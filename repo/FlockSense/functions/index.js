const functions = require('firebase-functions/v2');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const crypto = require('crypto');
const nodemailer = require('nodemailer');

admin.initializeApp();
const db = admin.firestore();

// Optional SMTP transporter for production email delivery (configured via environment)
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
  },
});

/**
 * Callable: sendEmailOtp
 * Generates a cryptographically secure 6-digit OTP and saves its hashed digest.
 */
exports.sendEmailOtp = functions.https.onCall(async (request) => {
  const email = (request.data?.email || '').trim().toLowerCase();
  if (!email || !email.includes('@')) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid email required.');
  }

  // Generate 6-digit numeric OTP
  const rawOtp = crypto.randomInt(100000, 999999).toString();
  const salt = crypto.randomBytes(16).toString('hex');
  const hashedOtp = crypto.scryptSync(rawOtp, salt, 32).toString('hex');

  const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes validity

  // Save to protected internal collection (Admin SDK only)
  await db.collection('_otp_verifications').doc(email).set({
    email,
    salt,
    hashedOtp,
    expiry,
    attempts: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send email if SMTP is configured, otherwise log in dev mode
  if (process.env.SMTP_USER) {
    try {
      await transporter.sendMail({
        from: `"FlockSense Poultry" <${process.env.SMTP_USER}>`,
        to: email,
        subject: 'FlockSense Verification Code',
        text: `Your verification code is: ${rawOtp}. Valid for 5 minutes. Do not share this code.`,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 500px;">
            <h2 style="color: #16A34A;">FlockSense Farm Security</h2>
            <p>Your verification code for FlockSense is:</p>
            <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0F172A; padding: 12px; background: #F1F5F9; border-radius: 8px; text-align: center;">
              ${rawOtp}
            </div>
            <p style="color: #64748B; font-size: 13px; margin-top: 16px;">This code will expire in 5 minutes. If you did not request this, please ignore this email.</p>
          </div>
        `,
      });
    } catch (err) {
      console.error('[sendEmailOtp] Failed to deliver SMTP email:', err);
    }
  } else {
    console.log(`[sendEmailOtp DEV] OTP for ${email}: ${rawOtp}`);
  }

  return { success: true, message: 'Verification code sent.' };
});

/**
 * Callable: verifyEmailOtp
 * Verifies user entered OTP against the scrypt hash.
 */
exports.verifyEmailOtp = functions.https.onCall(async (request) => {
  const email = (request.data?.email || '').trim().toLowerCase();
  const enteredOtp = (request.data?.otp || '').trim();

  if (!email || enteredOtp.length !== 6) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid email and 6-digit OTP required.');
  }

  const docRef = db.collection('_otp_verifications').doc(email);
  const snap = await docRef.get();

  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'No pending verification found. Please request a new code.');
  }

  const data = snap.data();

  // Check expiry
  if (data.expiry.toDate() < new Date()) {
    await docRef.delete();
    throw new functions.https.HttpsError('deadline-exceeded', 'Code expired. Please request a new code.');
  }

  // Max 3 attempts
  if (data.attempts >= 3) {
    await docRef.delete();
    throw new functions.https.HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
  }

  // Compute verify hash
  const computedHash = crypto.scryptSync(enteredOtp, data.salt, 32).toString('hex');
  const isValid = crypto.timingSafeEqual(Buffer.from(computedHash, 'hex'), Buffer.from(data.hashedOtp, 'hex'));

  if (!isValid) {
    await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
    return { verified: false, message: 'Incorrect verification code.' };
  }

  // Clean up on success
  await docRef.delete();
  return { verified: true, message: 'Verification successful.' };
});

/**
 * Daily Reminder Processing Core Logic
 * Inspects all users, checks active batches without today's telemetry record,
 * checks user scheduled reminder time and quiet hours, and dispatches FCM push notifications.
 */
async function processDailyReminders(forceCheck = false) {
  const now = new Date();
  const istFormatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });

  const parts = istFormatter.formatToParts(now);
  const partMap = {};
  for (const p of parts) {
    partMap[p.type] = p.value;
  }
  const todayDateStr = `${partMap.year}-${partMap.month}-${partMap.day}`;
  const currentHour = parseInt(partMap.hour, 10);

  console.log(`[processDailyReminders] Starting check. Date: ${todayDateStr}, Current IST Hour: ${currentHour}, forceCheck: ${forceCheck}`);

  const usersSnap = await db.collection('users').get();
  let notificationsSent = 0;

  for (const userDoc of usersSnap.docs) {
    const userId = userDoc.id;
    const userData = userDoc.data() || {};
    const fcmToken = userData.fcmToken;

    if (!fcmToken) continue;

    // Fetch user notification preferences
    let settings = {};
    try {
      const settingsDoc = await db
        .collection('users')
        .doc(userId)
        .collection('notification_settings')
        .doc('general')
        .get();
      if (settingsDoc.exists) {
        settings = settingsDoc.data() || {};
      }
    } catch (e) {
      console.warn(`[processDailyReminders] Error reading settings for ${userId}:`, e.message);
    }

    const dailyEnabled = settings.dailyReminderEnabled !== false;
    if (!dailyEnabled && !forceCheck) continue;

    // Scheduled reminder time (default 18:00 / 6:00 PM)
    const reminderTime = settings.dailyReminderTime || '18:00';
    const [targetHour] = reminderTime.split(':').map((s) => parseInt(s, 10) || 0);

    // If not forcing, check if this hour matches the target hour
    if (!forceCheck && currentHour !== targetHour) {
      continue;
    }

    // Check quiet hours
    if (settings.quietHoursEnabled && !settings.emergencyOverride && !forceCheck) {
      const [qStartH] = (settings.quietHoursStart || '22:00').split(':').map((s) => parseInt(s, 10) || 0);
      const [qEndH] = (settings.quietHoursEnd || '06:00').split(':').map((s) => parseInt(s, 10) || 0);
      if (qStartH > qEndH) {
        if (currentHour >= qStartH || currentHour < qEndH) continue;
      } else {
        if (currentHour >= qStartH && currentHour < qEndH) continue;
      }
    }

    // Check if user has active batches lacking today's daily record
    try {
      const farmsSnap = await db.collection('users').doc(userId).collection('farms').get();
      let hasMissingRecord = false;
      let targetBatchName = 'Flock';
      let targetBatchId = null;
      let targetFarmId = null;

      for (const farmDoc of farmsSnap.docs) {
        const batchesSnap = await farmDoc.ref
          .collection('batches')
          .where('status', '==', 'active')
          .limit(5)
          .get();

        for (const batchDoc of batchesSnap.docs) {
          const batchData = batchDoc.data() || {};
          const recordDoc = await batchDoc.ref.collection('dailyRecords').doc(todayDateStr).get();
          if (!recordDoc.exists) {
            hasMissingRecord = true;
            targetBatchName = batchData.batchName || 'Active Flock';
            targetBatchId = batchDoc.id;
            targetFarmId = farmDoc.id;
            break;
          }
        }
        if (hasMissingRecord) break;
      }

      if (hasMissingRecord) {
        const title = '🐔 Daily Telemetry Reminder';
        const body = `Time to record today's feed intake, water, and mortality for ${targetBatchName}.`;
        const notifId = `daily_reminder_${targetBatchId}_${todayDateStr}`;

        const payload = {
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data: {
            type: 'daily_record',
            screen: '/daily-records',
            farmId: targetFarmId || '',
            batchId: targetBatchId || '',
            date: todayDateStr,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'daily_reminders',
              sound: 'default',
              priority: 'high',
            },
          },
        };

        try {
          await admin.messaging().send(payload);
          notificationsSent++;
          console.log(`[processDailyReminders] Push sent to ${userId} for batch ${targetBatchName}`);

          // Also save in-app notification doc for Notification Center
          await db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notifId)
            .set({
              id: notifId,
              title,
              body,
              type: 'daily_record',
              priority: 'high',
              status: 'unread',
              relatedBatchId: targetBatchId,
              relatedFarmId: targetFarmId,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });

        } catch (err) {
          console.error(`[processDailyReminders] FCM delivery failed for ${userId}:`, err.message);
          if (
            err.code === 'messaging/registration-token-not-registered' ||
            err.code === 'messaging/invalid-registration-token'
          ) {
            await userDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
          }
        }
      }
    } catch (err) {
      console.error(`[processDailyReminders] Error checking user ${userId}:`, err.message);
    }
  }

  return { success: true, notificationsSent, date: todayDateStr };
}

/**
 * Scheduled Cloud Function (Cloud Scheduler v2)
 * Runs hourly to evaluate scheduled user reminder times and dispatch push notifications.
 */
exports.scheduledDailyReminder = onSchedule(
  {
    schedule: '0 * * * *',
    timeZone: 'Asia/Kolkata',
  },
  async (event) => {
    console.log('[scheduledDailyReminder] Starting hourly reminder dispatch check...');
    const result = await processDailyReminders(false);
    console.log('[scheduledDailyReminder] Completed. Reminders sent:', result.notificationsSent);
  }
);

/**
 * Callable: triggerDailyReminderCheck
 * On-demand test endpoint to trigger daily reminder evaluation.
 */
exports.triggerDailyReminderCheck = functions.https.onCall(async (request) => {
  const result = await processDailyReminders(true);
  return result;
});

