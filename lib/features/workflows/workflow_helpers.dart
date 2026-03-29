String triggerTypeLabel(int type) {
  return switch (type) {
    1 => 'Consumption',
    2 => 'Document Added',
    3 => 'Document Updated',
    4 => 'Removal',
    5 => 'Scheduled',
    _ => 'Unknown',
  };
}

String actionTypeLabel(int type) {
  return switch (type) {
    1 => 'Assignment',
    2 => 'Removal',
    3 => 'Email',
    _ => 'Unknown',
  };
}

String sourceLabel(int source) {
  return switch (source) {
    1 => 'Consume Folder',
    2 => 'API Upload',
    3 => 'Mail Fetch',
    _ => 'Unknown',
  };
}

String matchingAlgorithmLabel(int algorithm) {
  return switch (algorithm) {
    0 => 'None',
    1 => 'Any word',
    2 => 'All words',
    3 => 'Exact match',
    4 => 'RegEx',
    5 => 'Fuzzy',
    6 => 'Auto',
    _ => 'Unknown',
  };
}
