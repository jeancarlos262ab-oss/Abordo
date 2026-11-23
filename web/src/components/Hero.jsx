import { Play, LayoutDashboard, CheckCircle2 } from "lucide-react";
import Phone from "./Phone.jsx";
import QR from "./QR.jsx";

export default function Hero() {
  return (
    <section className="hero" aria-labelledby="t-hero">
      <svg className="route" viewBox="0 0 800 300" preserveAspectRatio="none" aria-hidden="true" focusable="false">
        <path d="M-20 240 C 150 60, 300 300, 460 140 S 700 60, 840 120" />
      </svg>
      <div className="hero-in">
        <div className="hero-text">
          <h1 id="t-hero">Abordo, el cobro del pasaje con CoDi</h1>
          <p>Escanea el QR de la unidad, paga $12 y sube. Sin cambio, sin comisión y sin que el chofer voltee a ver pantallas.</p>
          <div className="btns">
            <a href="#como-funciona" className="store"><Play size={22} fill="currentColor" aria-hidden="true" focusable="false" /><span><small>Mira el</small>Video demo</span></a>
            <a href="#como-funciona" className="store ghost"><LayoutDashboard size={22} aria-hidden="true" focusable="false" /><span><small>Abre el</small>Panel en vivo</span></a>
          </div>
        </div>
        <div className="phone-stage">
          <span className="ring" aria-hidden="true" /><span className="ring r2" aria-hidden="true" /><span className="ring r3" aria-hidden="true" />
          <div className="phone-tilt">
            <Phone variant="dark" label="Ejemplo de la pantalla del pasajero: QR de la unidad 14, ruta 52, y aviso de pago de 12 pesos confirmado.">
              <div className="paydemo">
                <small>Unidad 14 · Ruta 52</small>
                <div className="qr-wrap"><QR /></div>
                <b>$12.00</b>
                <div className="toast"><CheckCircle2 size={18} /> Pagó $12</div>
              </div>
            </Phone>
          </div>
        </div>
      </div>
    </section>
  );
}
