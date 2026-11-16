/// ข้อความ UI รวมไว้ที่เดียว (ไทยเป็นหลัก) · ย้ายไป flutter gen-l10n (.arb) เมื่อเพิ่มภาษาอังกฤษ
class S {
  const S._();

  static const appTitle = 'จองห้องประชุม';
  static const login = 'เข้าสู่ระบบ';
  static const logout = 'ออกจากระบบ';
  static const email = 'อีเมล';
  static const password = 'รหัสผ่าน';
  static const emailRequired = 'กรอกอีเมล';
  static const passwordRequired = 'กรอกรหัสผ่าน';
  static const loginFailed = 'เข้าสู่ระบบไม่สำเร็จ ตรวจอีเมลและรหัสผ่าน';
  static const myProfile = 'โปรไฟล์ของฉัน';
  static const displayName = 'ชื่อที่แสดง';
  static const notSet = 'ยังไม่ได้ตั้ง';
  static const loadFailed = 'โหลดข้อมูลไม่สำเร็จ';
  static const roomsComingSoon = 'รายการห้องและการจองจะมาในงานถัดไป (ROOM-2)';
  static const configError = 'ตั้งค่าแอปไม่ครบ';

  // ROOM-5 รายการห้อง
  static const announce =
      'จองล่วงหน้าได้ 30 วัน · ครั้งละ 15 นาที ถึง 4 ชั่วโมง';
  static const heroTitle = 'หาห้องว่าง\nจองได้ในไม่กี่แตะ';
  static String heroFreeNow(int free, int total) =>
      'ว่างตอนนี้ $free จาก $total ห้อง';
  static const greeting = 'สวัสดี';
  static const chooseDay = 'เลือกวัน';
  static const rooms = 'ห้องประชุม';
  static const noRooms = 'ยังไม่มีห้องที่เปิดให้จอง';
  static const retry = 'ลองอีกครั้ง';
  static const freeNow = 'ว่างตอนนี้';
  static String busyUntil(String t) => 'ไม่ว่างถึง $t';
  static const freeAllDay = 'ว่างทั้งวัน';
  static String bookedCount(int n) => 'จองแล้ว $n ช่วง';
  static String capacity(int n) => '$n คน';
  static const busyLabel = 'ไม่ว่าง';
  static const bookThisRoom = 'จองห้องนี้';
  static String bookRoom(String name) => 'จอง$name';
  static const mine = 'ของคุณ';
  static const infoNoOverlapTitle = 'ไม่มีจองซ้อน';
  static const infoNoOverlapBody =
      'ระบบกันไม่ให้สองคนจองห้องเดียวกันในเวลาเดียวกัน ตรวจที่ฐานข้อมูลทุกครั้ง';
  static const infoCancelTitle = 'ยกเลิกได้เอง';
  static const infoCancelBody =
      'ไม่ได้ใช้ห้องแล้ว ยกเลิกได้ก่อนเวลาประชุมจบ ห้องจะว่างให้คนอื่นทันที';
  static const infoPrivacyTitle = 'เป็นส่วนตัว';
  static const infoPrivacyBody =
      'คนอื่นเห็นแค่ว่าช่วงไหนไม่ว่าง ไม่เห็นชื่อผู้จองหรือหัวข้อประชุม';
  static const footer = 'Profender Room Booking · ภายในองค์กร';

  // ROOM-6 จองห้อง
  static const bookTitle = 'จองห้อง';
  static const date = 'วันที่';
  static const startTime = 'เวลาเริ่ม';
  static const endTime = 'เวลาจบ';
  static const timeHint = 'เช่น 09:30';
  static const meetingTitle = 'หัวข้อประชุม';
  static const meetingTitleHelper = 'เห็นเฉพาะคุณ คนอื่นเห็นแค่ว่าห้องไม่ว่าง';
  static const confirmBooking = 'ยืนยันการจอง';
  static const busyThatDay = 'ช่วงที่ไม่ว่างในวันนี้';
  static const booked = 'จองสำเร็จ';
  static const errBadStart = 'กรอกเวลาเริ่มเป็น ชม:นาที เช่น 09:30';
  static const errBadEnd = 'กรอกเวลาจบเป็น ชม:นาที เช่น 10:30';
  static const errNotQuarter = 'เวลาต้องลงท้าย :00 :15 :30 หรือ :45';
  static const errEndBeforeStart = 'เวลาจบต้องหลังเวลาเริ่ม';
  static const errTooShort = 'จองได้อย่างน้อย 15 นาที';
  static const errTooLong = 'จองได้ไม่เกิน 4 ชั่วโมงต่อครั้ง';
  static const errInPast = 'เวลานี้ผ่านไปแล้ว เลือกเวลาที่ยังไม่ถึง';
  static const errTooFar = 'จองล่วงหน้าได้ไม่เกิน 30 วัน';
  static const errTitle = 'กรอกหัวข้อประชุม';
  static const errOverlap = 'ช่วงเวลานี้มีคนจองแล้ว ลองเวลาอื่นหรือห้องอื่น';
  static const errInvalid = 'ข้อมูลการจองไม่ถูกต้อง';
  static const errNetwork = 'เชื่อมต่อไม่ได้ ลองอีกครั้ง';
  static const errEnded = 'การจองนี้จบไปแล้ว ยกเลิกไม่ได้';
  static const roomNotFound = 'ไม่พบห้องนี้';
}
