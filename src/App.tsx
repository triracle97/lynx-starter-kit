import { MemoryRouter, Routes, Route } from 'react-router'
import { Hello } from './routes/Hello'
import { Counter } from './routes/Counter'

export default function App() {
  return (
    <MemoryRouter>
      <Routes>
        <Route path="/" element={<Hello />} />
        <Route path="/counter" element={<Counter />} />
      </Routes>
    </MemoryRouter>
  )
}
