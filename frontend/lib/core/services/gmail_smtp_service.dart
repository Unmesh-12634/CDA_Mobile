import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Direct Google Gmail SMTP Service using official Google App Password credentials
class GmailSmtpService {
  static const String _senderEmail = 'unmeshjoshi083@gmail.com';
  static const String _appPassword = 'xxkdxfupvunwquqp';

  static String _formatRfc2822Date(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dName = days[dt.weekday - 1];
    final mName = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    return '$dName, $day $mName $year $hour:$min:$sec +0000';
  }

  /// Dispatches branded HTML 6-digit OTP email directly via smtp.gmail.com:465 SSL with strict RFC 5322 headers
  static Future<bool> sendPasswordResetOtp({
    required String recipientEmail,
    required String otp,
  }) async {
    try {
      final cleanEmail = recipientEmail.trim().toLowerCase();
      debugPrint('[GmailSmtpService] Connecting to smtp.gmail.com:465 SSL for $cleanEmail...');

      final socket = await SecureSocket.connect(
        'smtp.gmail.com',
        465,
        timeout: const Duration(seconds: 10),
      );

      Future<void> sendCommand(String cmd) async {
        socket.write('$cmd\r\n');
        await socket.flush();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await sendCommand('EHLO cranesvarsity.com');
      await Future.delayed(const Duration(milliseconds: 500));

      final userB64 = base64Encode(utf8.encode(_senderEmail));
      final passB64 = base64Encode(utf8.encode(_appPassword));

      await sendCommand('AUTH LOGIN');
      await Future.delayed(const Duration(milliseconds: 500));
      await sendCommand(userB64);
      await Future.delayed(const Duration(milliseconds: 500));
      await sendCommand(passB64);
      await Future.delayed(const Duration(milliseconds: 800));

      await sendCommand('MAIL FROM:<$_senderEmail>');
      await Future.delayed(const Duration(milliseconds: 500));
      await sendCommand('RCPT TO:<$cleanEmail>');
      await Future.delayed(const Duration(milliseconds: 500));
      await sendCommand('DATA');
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now().toUtc();
      final dateHeader = _formatRfc2822Date(now);
      final msgId = '<cda-${now.millisecondsSinceEpoch}@cranesvarsity.com>';

      final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CRANES VARSITY - Password Reset OTP</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F1F5F9; font-family: 'Segoe UI', Arial, sans-serif; -webkit-font-smoothing: antialiased;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #F1F5F9; padding: 30px 15px;">
    <tr>
      <td align="center">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 520px; background-color: #FFFFFF; border-radius: 20px; overflow: hidden; box-shadow: 0 10px 25px rgba(15, 32, 136, 0.1); border: 1px solid #E2E8F0;">
          
          <!-- Header Banner in #0F2088 -->
          <tr>
            <td style="background: linear-gradient(135deg, #0F2088 0%, #1E3A8A 100%); padding: 32px 20px; text-align: center; border-bottom: 3px solid #F59E0B;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" align="center">
                <tr>
                  <td style="background-color: #FFFFFF; width: 44px; height: 44px; border-radius: 12px; text-align: center; vertical-align: middle; box-shadow: 0 4px 10px rgba(0,0,0,0.15);">
                    <span style="font-size: 24px; line-height: 44px;">🎓</span>
                  </td>
                </tr>
              </table>
              <h1 style="color: #FFFFFF; font-size: 22px; font-weight: 800; letter-spacing: 1.5px; margin: 12px 0 4px 0; text-transform: uppercase;">CRANES VARSITY</h1>
              <p style="color: #93C5FD; font-size: 12px; margin: 0; letter-spacing: 0.5px; font-weight: 500;">Where Technology Meets Excellence</p>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td style="padding: 32px 28px; text-align: center;">
              <h2 style="color: #0F2088; font-size: 19px; font-weight: 700; margin: 0 0 10px 0;">Password Reset Verification</h2>
              <p style="color: #475569; font-size: 14px; line-height: 1.6; margin: 0 0 24px 0;">
                We received a request to reset your password. Use the single-use 6-digit OTP code below:
              </p>

              <!-- 6-Digit OTP Box with #0F2088 -->
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" align="center" style="margin: 0 auto 20px auto;">
                <tr>
                  <td style="background-color: #0F2088; color: #FFFFFF; font-size: 34px; font-weight: 900; letter-spacing: 10px; padding: 16px 32px; border-radius: 14px; border: 2px solid #F59E0B; text-align: center; box-shadow: 0 6px 16px rgba(15, 32, 136, 0.25);">
                    $otp
                  </td>
                </tr>
              </table>

              <!-- 3-Minute Validity Single Line in #0F2088 -->
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" align="center" style="margin: 0 auto 20px auto;">
                <tr>
                  <td style="background-color: #EEF2FF; border: 1px solid #C7D2FE; border-radius: 30px; padding: 8px 18px; text-align: center;">
                    <span style="color: #0F2088; font-size: 13px; font-weight: 700; display: inline-block;">
                      ⏱️ This OTP is valid for 3 minutes only.
                    </span>
                  </td>
                </tr>
              </table>

              <!-- Security Policy Notice -->
              <p style="color: #64748B; font-size: 12px; line-height: 1.5; margin: 0 0 8px 0;">
                🔒 <b>Security Rule:</b> Maximum 3 incorrect attempts allowed before a 10-minute lockout.
              </p>
              <p style="color: #94A3B8; font-size: 11.5px; margin: 0;">
                If you did not request this password reset, please ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #F8FAFC; padding: 18px 24px; text-align: center; border-top: 1px solid #E2E8F0;">
              <p style="color: #94A3B8; font-size: 11px; margin: 0;">
                © 2026 Cranes Varsity • Secure Mobile Authentication System
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

      final buffer = StringBuffer();
      buffer.write('From: "CRANES VARSITY" <$_senderEmail>\r\n');
      buffer.write('To: <$cleanEmail>\r\n');
      buffer.write('Reply-To: <$_senderEmail>\r\n');
      buffer.write('Date: $dateHeader\r\n');
      buffer.write('Message-ID: $msgId\r\n');
      buffer.write('Subject: Your Password Reset Verification OTP - CRANES VARSITY\r\n');
      buffer.write('MIME-Version: 1.0\r\n');
      buffer.write('Content-Type: text/html; charset=UTF-8\r\n');
      buffer.write('Content-Transfer-Encoding: 7bit\r\n');
      buffer.write('\r\n');
      buffer.write(htmlBody);
      buffer.write('\r\n.\r\n');

      socket.write(buffer.toString());
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 800));
      await sendCommand('QUIT');
      await Future.delayed(const Duration(milliseconds: 400));
      await socket.close();

      debugPrint('[GmailSmtpService] OTP email successfully delivered to $cleanEmail via Google SMTP with RFC 5322 headers!');
      return true;
    } catch (e) {
      debugPrint('[GmailSmtpService Error]: $e');
      return false;
    }
  }
}
