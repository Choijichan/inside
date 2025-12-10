// 분(minute) 단위를 HH:MM로 변환/파싱하는 유틸
String mmToHHmm(int mm) {
  final h = (mm ~/ 60).toString().padLeft(2, '0');
  final m = (mm % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

int hhmmToMM(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}
