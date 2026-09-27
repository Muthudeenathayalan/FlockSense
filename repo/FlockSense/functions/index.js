const functions = require('firebase-functions/v2');
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
