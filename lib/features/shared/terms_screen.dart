import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final points = [
      '平台只是媒合現場協助服務 / Queue Assistance matchmaking only.',
      '不保證任何政府、醫療、銀行、學校或私人機構一定受理。',
      '禁止冒名、代簽、插隊、賄賂、轉賣名額或違反現場規則。',
      'Runner 只能提供排隊、等候、提醒、拍照回報、現場資訊回報。',
      '若現場規則不允許第三方排隊，Runner 必須取消並回報。',
      '所有任務可被檢舉並由管理員審查。',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Terms / Términos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: points.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: Text(points[index]),
        ),
      ),
    );
  }
}
