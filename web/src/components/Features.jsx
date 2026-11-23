import { useState } from "react";
import { Truck } from "lucide-react";
import { TABS } from "../data/content.js";
import Phone from "./Phone.jsx";
import QR from "./QR.jsx";
import Reveal from "./Reveal.jsx";

function Feat({ Icon, title, text, delay }) {
  return (
    <li style={{ "--d": `${delay}ms` }}>
      <span className="ico"><Icon size={24} strokeWidth={1.75} aria-hidden="true" focusable="false" /></span>
      <h3>{title}</h3>
      <p>{text}</p>
    </li>
  );
}

export default function Features() {
  const names = Object.keys(TABS);
  const [tab, setTab] = useState(names[0]);
  const idx = names.indexOf(tab);
  const items = TABS[tab];
  const list = (arr, off) => arr.map(([I, t, d], i) => <Feat key={t} Icon={I} title={t} text={d} delay={(i + off) * 70} />);

  const onKey = (e, i) => {
    const next = { ArrowRight: (i + 1) % names.length, ArrowLeft: (i + names.length - 1) % names.length, Home: 0, End: names.length - 1 }[e.key];
    if (next === undefined) return;
    e.preventDefault();
    setTab(names[next]);
    document.getElementById(`tab-${next}`)?.focus();
  };

  return (
    <section id="funciones" className="slate deep" aria-labelledby="t-fn">
      <div className="inner">
        <h2 id="t-fn" className="sr">Pensado para quien paga, quien maneja y quien es dueño</h2>
        <div className="tabs" role="tablist" aria-label="Ver funciones por perfil">
          {names.map((t, i) => (
            <button key={t} id={`tab-${i}`} role="tab" aria-selected={tab === t} aria-controls="panel-fn" tabIndex={tab === t ? 0 : -1}
              className={tab === t ? "on" : ""} onClick={() => setTab(t)} onKeyDown={(e) => onKey(e, i)}>{t}</button>
          ))}
        </div>
        <div id="panel-fn" role="tabpanel" aria-labelledby={`tab-${idx}`} tabIndex={0} className="feat-grid" key={tab}>
          <ul role="list" className="col l">{list(items.slice(0, 3), 0)}</ul>
          <Reveal className="mid">
            <Phone label="Ejemplo de la pantalla de pago: unidad 14, ruta 52, QR y botón Pagar con CoDi por 12 pesos.">
              <div className="app">
                <small>Unidad 14 · Ruta 52</small>
                <div className="avatar"><Truck size={24} color="#161314" /></div>
                <QR />
                <div className="field">Pasaje: $12.00</div>
                <div className="cta">Pagar con CoDi</div>
                <em>Escanea con tu app del banco</em>
              </div>
            </Phone>
          </Reveal>
          <ul role="list" className="col r">{list(items.slice(3), 3)}</ul>
        </div>
      </div>
    </section>
  );
}
