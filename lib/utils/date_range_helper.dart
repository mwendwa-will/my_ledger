DateTime exclusiveEndDate(DateTime inclusiveEndDate) {
  return DateTime(
    inclusiveEndDate.year,
    inclusiveEndDate.month,
    inclusiveEndDate.day + 1,
  );
}
