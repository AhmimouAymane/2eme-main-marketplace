import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import { ConfigProvider } from 'antd'

ReactDOM.createRoot(document.getElementById('root')!).render(
    <React.StrictMode>
        <ConfigProvider theme={{
            token: {
                colorPrimary: '#2e7d32', // Clovi Green
            },
            components: {
                Layout: {
                    headerBg: '#fff',
                }
            }
        }}>
            <App />
        </ConfigProvider>
    </React.StrictMode>,
)
