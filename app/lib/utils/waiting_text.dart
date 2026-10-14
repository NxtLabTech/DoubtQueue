String waitingText(int count) {
  if (count == 0) {
    return 'No students waiting';
  }
  if (count == 1) {
    return '1 student waiting';
  }
  return '$count students waiting';
}
