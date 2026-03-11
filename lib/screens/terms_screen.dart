import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('利用規約 Terms'),
        backgroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          '''
利用規約 Terms of Use

第1条（適用） Article 1 (Application)
本規約は、Magical Vibe（以下「本サービス」）の利用条件を定めるものです。
These Terms set forth the conditions for using Magical Vibe (hereinafter referred to as “the Service”).

第2条（サービス内容） Article 2 (Service Description)
本サービスは、ユーザーがクレジットを利用して精霊動画生成機能を利用できる Web サービスです。
The Service is a web service that allows users to utilize the spirit video generation feature using credits.

第3条（アカウント） Article 3 (Account)
ユーザーは、Google アカウント等を用いてログインし、本サービスを利用するものとします。
Users shall log in using a Google Account or similar and use the Service.

第4条（クレジット） Article 4 (Credits)
1. ユーザーは、本サービス内でクレジットを購入できます。
   Users may purchase credits within the Service.
2. クレジットは、本サービス内の動画生成機能の利用にのみ使用できます。
   Credits may only be used for the video generation feature within the Service.
3. 購入済みクレジットは、法令上必要な場合を除き、現金への換金はできません。
   Purchased credits cannot be redeemed for cash, except where required by law.

第5条（支払） Article 5 (Payment)
本サービスの決済は Stripe Checkout を通じて行われます。
Payments for the Service are processed through Stripe Checkout.

第6条（禁止事項） Article 6 (Prohibited Acts)
ユーザーは、以下の行為を行ってはなりません。
Users shall not engage in the following acts:
・法令または公序良俗に違反する行為
  Acts violating laws, regulations, or public order and morals
・本サービスの運営を妨害する行為
  Acts interfering with the operation of the Service
・不正アクセスまたはそれを試みる行為
  Unauthorized access or attempts thereof
・他者になりすます行為
  Impersonating another person

第7条（サービス停止・変更） Article 7 (Service Suspension/Modification)
当社は、保守、障害対応、その他必要な場合に、本サービスの全部または一部を停止または変更することがあります。
The Company may suspend or modify all or part of the Service for maintenance, troubleshooting, or other necessary reasons.

第8条（免責） Article 8 (Disclaimer)
当社は、本サービスの利用によって生じた損害について、当社に故意または重過失がある場合を除き、責任を負いません。
The Company shall not be liable for any damages arising from the use of the Service, except in cases where the Company acted with intent or gross negligence.

第9条（規約変更） Article 9 (Amendment of Terms)
当社は、必要に応じて本規約を変更できるものとします。
The Company may amend these Terms as necessary.

第10条（準拠法） Article 10 (Governing Law)
本規約は日本法に準拠します。
These Terms shall be governed by and construed in accordance with the laws of Japan.
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