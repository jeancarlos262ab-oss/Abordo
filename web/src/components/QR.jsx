const SIZE = 11;
const isFinder = (r, c) => (r < 3 && c < 3) || (r < 3 && c >= SIZE - 3) || (r >= SIZE - 3 && c < 3);

export default function QR() {
  const cells = [];
  for (let r = 0; r < SIZE; r++)
    for (let c = 0; c < SIZE; c++) cells.push(isFinder(r, c) || (r * 7 + c * 13 + r * c) % 3 === 0);
  return (
    <div className="qr" style={{ gridTemplateColumns: `repeat(${SIZE},1fr)` }}>
      {cells.map((on, i) => <i key={i} className={on ? "on" : ""} />)}
    </div>
  );
}
