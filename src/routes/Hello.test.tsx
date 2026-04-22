import { test, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { Hello } from './Hello'

test('Hello screen renders greeting and link', () => {
  render(
    <MemoryRouter>
      <Hello />
    </MemoryRouter>,
  )
  expect(screen.getByText('Hello Lynx')).toBeTruthy()
  expect(screen.getByText(/Go to Counter/)).toBeTruthy()
})
