/** ช่วงเวลาสุ่มในอนาคต (2–28 วันข้างหน้า, ลงตัว 15 นาที) เพื่อไม่ให้ test ที่รันซ้ำบนฐานเดียวกันชนกัน */
export function randomSlot(minutes = 60, base?: Date) {
  const start = base ? new Date(base) : new Date();
  if (!base) {
    start.setUTCDate(start.getUTCDate() + 2 + Math.floor(Math.random() * 26));
    start.setUTCHours(Math.floor(Math.random() * 18), [0, 15, 30, 45][Math.floor(Math.random() * 4)], 0, 0);
  }
  const end = new Date(start.getTime() + minutes * 60_000);
  return { start, end, starts_at: start.toISOString(), ends_at: end.toISOString() };
}
