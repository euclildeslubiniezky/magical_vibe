import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('プライバシーポリシー Privacy'),
        backgroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          '''
プライバシーポリシー Privacy Policy

Magical Vibe は、以下の方針に基づき、ユーザー情報を取り扱います。
Magical Vibe handles user information based on the following policies.

1. 取得する情報 Information Collected
・ログインに必要なアカウント情報 Account information required for login
・メールアドレス Email address
・決済結果に関する情報 Information regarding payment results
・サービス利用状況に関する情報 Information regarding service usage

2. 利用目的 Purpose of Use
・本サービスの提供 Providing this service
・購入クレジットの反映 Reflecting purchased credits
・問い合わせ対応 Responding to inquiries
・不正利用防止 Preventing fraudulent use
・サービス改善 Improving the service

3. 決済情報について Payment Information
クレジットカード情報は Stripe により処理され、当サービス運営者はカード番号等の完全な情報を保持しません。
Credit card information is processed by Stripe. The service operator does not retain complete card details such as card numbers.

4. 第三者提供 Disclosure to Third Parties
法令に基づく場合を除き、ユーザー情報を第三者へ提供しません。
User information will not be disclosed to third parties except as required by law.

5. 安全管理 Security Measures
取得した情報は、不正アクセス、漏えい、改ざん等の防止に努めて適切に管理します。
Acquired information will be managed appropriately to prevent unauthorized access, leakage, alteration, and other risks.

6. お問い合わせ Contact Us
euclildes.lubiniezky@gmail.com
''',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}