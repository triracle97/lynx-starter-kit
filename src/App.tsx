import { MemoryRouter, Routes, Route } from 'react-router'

export default function App() {
  return (
    <MemoryRouter>
      <Routes>
        <Route path="/" element={null} />
      </Routes>
    </MemoryRouter>
  )
}
