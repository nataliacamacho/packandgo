int levenshtein(String a, String b) {
  List<List<int>> dp = List.generate(
    a.length + 1,
    (_) => List.filled(b.length + 1, 0),
  );

  for (int i = 0; i <= a.length; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= b.length; j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      int cost = a[i - 1] == b[j - 1] ? 0 : 1;

      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[a.length][b.length];
}

bool coincideRuta(String texto, String query) {
  texto = texto.toLowerCase();
  query = query.toLowerCase();

  return texto.contains(query) ||
      levenshtein(texto, query) <= 3; // tolerancia de error
}