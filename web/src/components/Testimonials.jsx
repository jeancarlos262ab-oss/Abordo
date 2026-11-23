import { useEffect, useState } from "react";
import { Star } from "lucide-react";
import { OPINIONES } from "../data/content.js";
import Reveal from "./Reveal.jsx";

export default function Testimonials() {
  const [active, setActive] = useState(0);
  useEffect(() => {
    // Rota sola, salvo que el sistema pida menos movimiento.
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const t = setInterval(() => setActive((a) => (a + 1) % OPINIONES.length), 4000);
    return () => clearInterval(t);
  }, []);
  return (
    <section id="opiniones" className="slate" aria-labelledby="t-op">
      <div className="inner">
        <h2 id="t-op" className="sr">Lo que dicen choferes, dueños y pasajeros</h2>
        <ul role="list" className="quotes">
          {OPINIONES.map(([q, n, r], i) => (
            <li key={n}>
              <Reveal as="figure" delay={i * 90} className={i === active ? "active" : ""}>
                <div className="stars" role="img" aria-label="5 de 5 estrellas">
                  {[0, 1, 2, 3, 4].map((s) => <Star key={s} size={16} fill="var(--pink)" stroke="var(--pink)" aria-hidden="true" />)}
                </div>
                <blockquote>{q}</blockquote>
                <figcaption><b>{n}</b><span>{r}</span></figcaption>
              </Reveal>
            </li>
          ))}
        </ul>
        <div className="dots" role="group" aria-label="Resaltar opinión">
          {OPINIONES.map((o, i) => (
            <button key={o[1]} aria-label={`Opinión de ${o[1]}`} aria-pressed={i === active} className={i === active ? "on" : ""} onClick={() => setActive(i)} />
          ))}
        </div>
      </div>
    </section>
  );
}
