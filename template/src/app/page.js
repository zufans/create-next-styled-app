"use client";
import styled from "styled-components";
const Main = styled.main`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 4rem;
`;

const Title = styled.h1`
  font-size: 4rem;
  color: ${({ theme }) => theme.colors.primary};
  margin-bottom: ${({ theme }) => theme.spacing.lg};
`;

const Description = styled.p`
  font-size: 1.5rem;
`;

export default function Home() {
  return (
    <Main>
      <Title>Welcome!</Title>
      <Description>Your styled-components setup is working.</Description>
    </Main>
  );
}
