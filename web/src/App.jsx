import Header from "./components/Header.jsx";
import Hero from "./components/Hero.jsx";
import Testimonials from "./components/Testimonials.jsx";
import Features from "./components/Features.jsx";
import Facts from "./components/Facts.jsx";
import Footer from "./components/Footer.jsx";

export default function App() {
  return (
    <div className="ab">
      <a className="skip" href="#contenido">Saltar al contenido</a>
      <Header />
      <main id="contenido" tabIndex={-1}>
        <Hero />
        <Testimonials />
        <Features />
        <Facts />
      </main>
      <Footer />
    </div>
  );
}
