import { PASOS } from "../data/content.js";
import Phone from "./Phone.jsx";
import Reveal from "./Reveal.jsx";

const CHOFERES = [["Marcos", "$1,240", 100], ["Ana", "$980", 79], ["Daniel", "$860", 69]];

export default function Facts() {
  return (
    <section className="facts" id="como-funciona" aria-labelledby="t-how">
      <div className="inner">
        <Reveal as="h2" id="t-how">Así funciona</Reveal>
        <Reveal as="p" className="lead" delay={80}>Un dueño, sus unidades y un QR en cada una. Esto pasa desde que el pasajero sube hasta que cierra el turno.</Reveal>
        <ol role="list" className="steps">
          {PASOS.map(([t, d], i) => (
            <Reveal as="li" key={t} delay={i * 140}>
              <span className="num" aria-hidden="true">{i + 1}</span>
              <div><h3>{t}</h3><p>{d}</p></div>
            </Reveal>
          ))}
        </ol>
      </div>
      <Reveal className="phone-low" delay={200}>
        <Phone className="land" label="Ejemplo del panel del dueño con el celular de lado: total de cobros del día, gráfica y cobros por chofer, con Marcos en primer lugar.">
          <div className="panel">
            <div className="tot">
              <b><i className="live" /> Cobros de hoy</b>
              <strong>$3,080</strong>
              <small>Ejemplo de cuadre del día</small>
            </div>
            <svg viewBox="0 0 200 60" preserveAspectRatio="none">
              <polyline pathLength="1" points="0,50 25,40 50,44 75,26 100,32 125,16 150,22 175,10 200,16" />
            </svg>
            <ul>
              {CHOFERES.map(([n, v, w]) => (
                <li key={n}><span>{n}</span><i style={{ width: `${w}%` }} /><b>{v}</b></li>
              ))}
            </ul>
          </div>
        </Phone>
      </Reveal>
    </section>
  );
}
