enum EstadoViaje {
  futuro,
  actual,
  pasado,
  cancelado,
}

class ViajeEstadoUtil {
  static EstadoViaje obtenerEstado({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required bool cancelado,
  }) {
    final hoy = DateTime.now();

    // Normalizamos fechas (sin horas para evitar errores)
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

    if (cancelado) return EstadoViaje.cancelado;

    if (hoySinHora.isBefore(inicio)) {
      return EstadoViaje.futuro;
    } else if (hoySinHora.isAfter(fin)) {
      return EstadoViaje.pasado;
    } else {
      return EstadoViaje.actual;
    }
  }

  static String textoEstado(EstadoViaje estado) {
    switch (estado) {
      case EstadoViaje.futuro:
        return "Futuro";
      case EstadoViaje.actual:
        return "En curso";
      case EstadoViaje.pasado:
        return "Finalizado";
      case EstadoViaje.cancelado:
        return "Cancelado";
    }
  }
}