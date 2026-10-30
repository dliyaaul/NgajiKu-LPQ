class AttendanceModule {
  final String id;
  final String title;
  final String description;
  final String iconKey;

  const AttendanceModule({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
  });
}

const attendanceModules = <AttendanceModule>[
  AttendanceModule(
    id: 'bbaq',
    title: 'BBAQ',
    description: 'Absensi pertemuan dan santri BBAQ',
    iconKey: 'menu_book',
  ),
  AttendanceModule(
    id: 'tahfidz',
    title: 'Tahfidz',
    description: 'Absensi pertemuan dan santri Tahfidz',
    iconKey: 'auto_stories',
  ),
  AttendanceModule(
    id: 'tarjamah',
    title: 'Tarjamah',
    description: 'Absensi pertemuan dan santri Tarjamah',
    iconKey: 'translate',
  ),
  AttendanceModule(
    id: 'ptl',
    title: 'PTL',
    description: 'Modul absensi PTL',
    iconKey: 'school',
  ),
];
