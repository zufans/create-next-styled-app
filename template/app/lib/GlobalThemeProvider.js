"use client";

import { ThemeProvider } from "styled-components";
import { theme } from "./theme";
import GlobalStyles from "./globalStyles";

export default function GlobalThemeProvider({ children }) {
  return (
    <ThemeProvider theme={theme}>
      <GlobalStyles />
      {children}
    </ThemeProvider>
  );
}
