import { useState } from 'react'
import { useNavigate } from 'react-router'
import { center, link } from '../styles'

export function Counter() {
  const [n, setN] = useState(0)
  const nav = useNavigate()
  return (
    <view style={center}>
      <text style={{ fontSize: 48, marginBottom: 16 }}>{n}</text>
      <view style={{ flexDirection: 'row', marginBottom: 24 }}>
        <view bindtap={() => setN(n - 1)} onClick={() => setN(n - 1)} style={{ padding: 12 }}>
          <text style={{ fontSize: 28 }}>−</text>
        </view>
        <view bindtap={() => setN(n + 1)} onClick={() => setN(n + 1)} style={{ padding: 12 }}>
          <text style={{ fontSize: 28 }}>+</text>
        </view>
      </view>
      <view bindtap={() => nav(-1)} onClick={() => nav(-1)} style={{ padding: 12 }}>
        <text style={link}>← Back</text>
      </view>
    </view>
  )
}
