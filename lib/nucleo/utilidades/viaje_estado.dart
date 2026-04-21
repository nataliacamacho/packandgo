enum EstadoViaje {
  futuro,
  actual,
  pasado,
}

class ViajeEstadoUtil {
  static EstadoViaje obtenerEstado({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    final hoy = DateTime.now();

    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

    if (hoySinHora.isBefore(inicio)) {
      return EstadoViaje.futuro;
    } else if (hoySinHora.isAfter(fin)) {
      return EstadoViaje.pasado;
    } else {
      return EstadoViaje.actual;
    }
  }
}