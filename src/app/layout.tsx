import projectInfo from '@/projectInfo';
import type { Metadata } from 'next';
// import './styles/globals.css';

export const metadata: Metadata = {
  title: projectInfo.company.name,
  description: projectInfo.company.description,
};

const RootLayout = ({ children }: Readonly<{children: React.ReactNode}>) => {
  return (
    <html lang='en'>
        <body className=''>{children}</body>
    </html>
  );
}

export default RootLayout
