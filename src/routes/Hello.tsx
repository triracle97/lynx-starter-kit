import { useNavigate } from 'react-router'
import { center, link } from '../styles'

export function Hello() {
  const nav = useNavigate()
  return (
    <view style={center}>
      <text style={{ fontSize: 32, marginBottom: 24 }}>Hello Lynx</text>
      <view bindtap={() => nav('/counter')} onClick={() => nav('/counter')} style={{ padding: 12 }}>
        <text style={link}>Go to Counter →</text>
      </view>
    </view>
  )
}
