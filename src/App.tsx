import { MemoryRouter, Routes, Route } from 'react-router'
import { Hello } from './routes/Hello'

export default function App() {
  return (
    <MemoryRouter>
      <Routes>
        <Route path="/" element={<Hello />} />
      </Routes>
    </MemoryRouter>
  )
}
