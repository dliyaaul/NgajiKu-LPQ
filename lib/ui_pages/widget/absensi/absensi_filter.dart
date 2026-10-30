import 'package:flutter/material.dart';

enum AbsensiPbm { offline, online }

extension AbsensiPbmExtension on AbsensiPbm {
  String get label {
    switch (this) {
      case AbsensiPbm.offline:
        return 'Offline';
      case AbsensiPbm.online:
        return 'Online';
    }
  }

  String get value {
    switch (this) {
      case AbsensiPbm.offline:
        return 'Offline';
      case AbsensiPbm.online:
        return 'Online';
    }
  }
}

class AbsensiFilterState {
  final DateTimeRange? dateRange;
  final String? pengajarId;
  final AbsensiPbm? pbm;

  const AbsensiFilterState({this.dateRange, this.pengajarId, this.pbm});

  bool get hasActiveFilter {
    return dateRange != null ||
        (pengajarId != null && pengajarId!.isNotEmpty) ||
        pbm != null;
  }

  AbsensiFilterState copyWith({
    DateTimeRange? dateRange,
    String? pengajarId,
    AbsensiPbm? pbm,
    bool clearDateRange = false,
    bool clearPengajar = false,
    bool clearPbm = false,
  }) {
    return AbsensiFilterState(
      dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
      pengajarId: clearPengajar ? null : pengajarId ?? this.pengajarId,
      pbm: clearPbm ? null : pbm ?? this.pbm,
    );
  }

  AbsensiFilterState clear() {
    return const AbsensiFilterState();
  }
}
