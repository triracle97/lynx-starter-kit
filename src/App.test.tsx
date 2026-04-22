import { test, expect } from 'vitest'
import { render } from '@testing-library/react'
import App from './App'

test('App renders without throwing', () => {
  expect(() => render(<App />)).not.toThrow()
})
