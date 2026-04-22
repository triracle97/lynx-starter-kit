import { test, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { Counter } from './Counter'

test('Counter increments and decrements', () => {
  render(
    <MemoryRouter>
      <Counter />
    </MemoryRouter>,
  )
  expect(screen.getByText('0')).toBeTruthy()
  fireEvent.click(screen.getByText('+'))
  expect(screen.getByText('1')).toBeTruthy()
  fireEvent.click(screen.getByText('−'))
  expect(screen.getByText('0')).toBeTruthy()
})
