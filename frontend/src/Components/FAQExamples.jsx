import React, { useState, useEffect } from "react";
import { TEXT } from "../utilities/constants";
import { useLanguage } from "../utilities/LanguageContext"; // Adjust the import path
import { Box, Button, Grid } from "@mui/material";

const shuffleArray = (array) => {
  return array.sort(() => Math.random() - 0.5);
};

const FAQExamples = ({ onPromptClick, showLeftNav = true }) => {
  const { currentLanguage } = useLanguage();
  const [faqs, setFaqs] = useState([]);

  useEffect(() => {
    // Shuffle FAQs on initial render and when left nav state changes
    const questionCount = showLeftNav ? 4 : 5;
    const shuffledFAQs = shuffleArray([...TEXT[currentLanguage].FAQS]).slice(0, questionCount);
    setFaqs(shuffledFAQs);
  }, [currentLanguage, showLeftNav]);

  return (
    <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
      <Grid container spacing={1}>
        {faqs.map((prompt, index) => (
          <Grid item key={index} xs={showLeftNav ? 3 : 2.4}>
            <Button
              variant="outlined"
              size="small"
              onClick={() => onPromptClick(prompt)}
              sx={{
                width: "100%",
                textAlign: "left", 
                textTransform: "none", // Prevent text from being uppercase
              }}
            >
              {prompt}
            </Button>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default FAQExamples;
