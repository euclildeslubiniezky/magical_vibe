import 'package:flutter/material.dart';

class RefundScreen extends StatelessWidget {
  const RefundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('返金・キャンセル Refund'),
        backgroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          '''
返金・キャンセルポリシー Refund and Cancellation Policy

Magical Vibe はデジタルサービスのため、購入済みクレジットの返金・返品は原則として受け付けておりません。
As Magical Vibe is a digital service, refunds or returns for purchased credits are generally not accepted.

ただし、以下の場合は個別に確認のうえ対応します。
However, we will review and address the following cases individually.
・決済が重複して行われた場合 If a payment was processed twice
・システム障害によりクレジットが正常に反映されなかった場合 If credits were not properly reflected due to a system failure
・その他、当社が返金対応を妥当と判断した場合 Other cases where we deem a refund appropriate

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