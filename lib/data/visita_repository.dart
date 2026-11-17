import '../models/visita.dart';

/// Contrato para guardar y leer visitas.
///
/// Las pantallas dependen de esta abstracción y no de SQLite
/// (Inversión de Dependencias). Si mañana se cambia SQLite por
/// SharedPreferences o una API, solo se escribe otra implementación.
abstract class VisitaRepository {
  /// Todas las visitas, de la más reciente a la más antigua.
  Future<List<Visita>> obtenerTodas();

  /// Visitas a un restaurante (sin distinguir mayúsculas), de la más
  /// reciente a la más antigua. [excluirId] sirve para dejar fuera la
  /// visita que se está viendo.
  Future<List<Visita>> obtenerDeRestaurante(String restaurante, {int? excluirId});

  /// Nombres de los restaurantes ya visitados, sin repetir.
  Future<List<String>> obtenerRestaurantes();

  /// Inserta la visita y devuelve el id generado.
  Future<int> insertar(Visita visita);

  Future<void> eliminar(int id);
}
