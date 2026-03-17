import 'package:flutter/material.dart';

class CommerceDisclosureScreen extends StatelessWidget {
  const CommerceDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('特定商取引法に基づく表記 / Commerce Disclosure'),
        backgroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: SelectableText(
          '''
特定商取引法に基づく表記 Commerce Disclosure

【販売事業者名 / Seller】
赤松　卓 Suguru Akamatsu 

【運営責任者 / Operator】
赤松　卓 Suguru Akamatsu

【所在地 / Business Address】
〒174-0071 東京都板橋区常盤台3-19-6-407 アンジュエ常盤台
Anjuetokiwadai 3-19-6-407 Tokiwadai Itabashi-ku Tokyo-to Japan 174-0071

【電話番号 / Phone Number】
090-7784-3661

※日本語での対応が可能です。
* Support is available in Japanese.
※電話は日本語対応のみです。英語での電話対応は行っておりません。
* Phone support is provided in Japanese only. English phone support is not available.

【メールアドレス / Email】
euclildes.lubiniezky@gmail.com

【サイトURL / Website】
https://magicalvibe-e3e86.web.app/

【販売価格 / Price】
3 credits: 500円（税込）3 credits: JPY 500 (tax included)
10 credits: 1,500円（税込）10 credits: JPY 1,500 (tax included)
20 credits: 2,800円（税込）20 credits: JPY 2,800 (tax included)

【商品代金以外の必要料金 / Additional Fees】
インターネット接続料金、通信料金等はお客様のご負担となります。
Internet connection fees and communication charges are the responsibility of the customer.

【支払方法 / Payment Method】
クレジットカード決済（Stripe Checkout）
Credit card payment (Stripe Checkout)

【支払時期 / Payment Timing】
購入手続き時にお支払いが確定します。
Payment is confirmed at the time of purchase.

【商品の提供時期 / Delivery Timing】
決済完了後、通常は数秒から数分以内にアカウントへクレジットが反映されます。
After payment is completed, credits are usually reflected in the account within a few seconds to a few minutes.
システム都合により反映に時間がかかる場合があります。
In some cases, reflection may take longer due to system conditions.

【販売数量 / Quantity】
各商品ページに記載のとおりです。
As described on each product page.

【返品・キャンセルについて / Refunds and Cancellations】
デジタル商品の性質上、決済完了後のお客様都合による返金・キャンセルは原則としてお受けしておりません。
Due to the nature of digital products, refunds or cancellations for customer convenience are generally not accepted after payment is completed.
ただし、重複決済、システム障害による未反映、その他運営者が妥当と判断した場合は個別に対応いたします。
However, duplicate payments, failed credit delivery due to system issues, or other cases deemed appropriate by the operator will be reviewed individually.

【動作環境 / System Requirements】
最新版の主要ブラウザ（Google Chrome、Safari、Microsoft Edge など）と安定したインターネット接続環境が必要です。
A recent version of a major browser (such as Google Chrome, Safari, or Microsoft Edge) and a stable internet connection are required.

【商品の内容 / Service Description】
Magical Vibe は、AI による精霊動画生成のためのデジタルクレジットを販売する Web アプリです。
Magical Vibe is a web application that sells digital credits for AI spirit video generation.

ユーザーはログイン後、クレジットを購入し、そのクレジットを使ってアプリ内で動画生成を行います。物理商品の発送はありません。
Users log in, purchase credits, and use those credits to generate videos inside the app. No physical goods are shipped.
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
