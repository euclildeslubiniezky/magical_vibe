import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('お問い合わせ Contact'),
        backgroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          '''
サービス名 Service Name
Magical Vibe

提供内容 Service Description
Magical Vibe は、精霊動画生成機能をクレジット制で提供する Web アプリです。
Magical Vibe is a web application that provides spirit video generation functionality on a credit-based system.
ユーザーはクレジットを購入し、そのクレジットを使って動画生成を行います。
Users purchase credits and use them to generate videos.

販売価格 Pricing
3 credits: 500円（税込） 3 credits: ¥500 (tax included)
10 credits: 1,500円（税込） 10 credits: ¥1,500 (tax included)
20 credits: 2,800円（税込） 20 credits: ¥2,800 (tax included)

支払方法 Payment Methods
クレジットカード決済（Stripe Checkout）
Credit card payment (Stripe Checkout)

クレジット反映時期 Credit Reflection Timing
決済完了後、通常は数秒から数分以内にアカウントへ反映されます。
Credits are typically reflected in your account within seconds to minutes after payment completion.

お問い合わせ先 Contact Information
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