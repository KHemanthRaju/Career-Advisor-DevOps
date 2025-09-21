import React, { useState, useEffect } from 'react';
import { Box, Typography } from '@mui/material';
import { PERSONAS } from './PersonaSelector';

function Avatar3DRealistic({ persona = 'architect', isThinking = false, isSpeaking = false, isListening = false, message = '' }) {
  const [blinkState, setBlinkState] = useState(false);
  const [headRotation, setHeadRotation] = useState({ x: 0, y: 0 });
  const [mouthState, setMouthState] = useState('closed');
  const [expression, setExpression] = useState('neutral');
  const [eyebrowPosition, setEyebrowPosition] = useState(0);

  // Natural blinking
  useEffect(() => {
    const blinkInterval = setInterval(() => {
      setBlinkState(true);
      setTimeout(() => setBlinkState(false), 120);
    }, 2000 + Math.random() * 3000);
    return () => clearInterval(blinkInterval);
  }, []);

  // Head movement for thinking
  useEffect(() => {
    if (isThinking) {
      const moveInterval = setInterval(() => {
        setHeadRotation({
          x: (Math.random() - 0.5) * 10,
          y: (Math.random() - 0.5) * 15
        });
      }, 1500);
      return () => clearInterval(moveInterval);
    } else {
      setHeadRotation({ x: 0, y: 0 });
    }
  }, [isThinking]);

  // Dynamic expression based on message content
  useEffect(() => {
    if (message) {
      const lowerMessage = message.toLowerCase();
      
      if (lowerMessage.includes('error') || lowerMessage.includes('problem') || lowerMessage.includes('issue')) {
        setExpression('concerned');
        setEyebrowPosition(-5);
      } else if (lowerMessage.includes('great') || lowerMessage.includes('excellent') || lowerMessage.includes('success')) {
        setExpression('happy');
        setEyebrowPosition(2);
      } else if (lowerMessage.includes('?') || lowerMessage.includes('help') || lowerMessage.includes('how')) {
        setExpression('thoughtful');
        setEyebrowPosition(-2);
      } else if (lowerMessage.includes('welcome') || lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
        setExpression('friendly');
        setEyebrowPosition(1);
      } else {
        setExpression('neutral');
        setEyebrowPosition(0);
      }
    }
  }, [message]);

  // Mouth animation for speaking
  useEffect(() => {
    if (isSpeaking) {
      const mouthInterval = setInterval(() => {
        const states = expression === 'happy' ? ['smile', 'half-open', 'smile'] : ['open', 'half-open', 'closed'];
        setMouthState(states[Math.floor(Math.random() * states.length)]);
      }, 200);
      return () => clearInterval(mouthInterval);
    } else {
      if (expression === 'happy' || expression === 'friendly') {
        setMouthState('smile');
      } else if (expression === 'concerned') {
        setMouthState('frown');
      } else {
        setMouthState(isListening ? 'smile' : 'closed');
      }
    }
  }, [isSpeaking, isListening, expression]);

  const getPersonaStyle = (personaKey) => {
    // Pawan Kalyan inspired styling - charismatic leader
    const baseStyle = {
      skinTone: '#E8B982', // Warm Indian skin tone
      hairColor: '#2C1810', // Dark black hair
      eyeColor: '#4A2C2A', // Deep brown expressive eyes
      beardColor: '#1A1A1A', // Well-groomed beard
      mustacheColor: '#2C1810' // Signature mustache
    };
    
    const styles = {
      architect: {
        ...baseStyle,
        accent: '#FF6B35', // Saffron/Orange (political colors)
        shirtColor: '#FFFFFF', // White kurta/shirt
        personality: 'charismatic-leader'
      },
      engineer: {
        ...baseStyle,
        accent: '#2196F3',
        shirtColor: '#FFFFFF',
        personality: 'tech-hero'
      },
      mentor: {
        ...baseStyle,
        accent: '#FF9800',
        shirtColor: '#FFFFFF',
        personality: 'wise-guide'
      },
      interviewer: {
        ...baseStyle,
        accent: '#9C27B0',
        shirtColor: '#FFFFFF',
        personality: 'confident-professional'
      }
    };
    return styles[personaKey] || styles.architect;
  };

  const style = getPersonaStyle(persona);

  const getFloatingAnimation = () => {
    if (isThinking) return 'thinking-float 3s ease-in-out infinite';
    if (isSpeaking) return 'speaking-bounce 0.5s ease-in-out infinite';
    if (isListening) return 'listening-glow 2s ease-in-out infinite';
    return 'idle-float 4s ease-in-out infinite';
  };

  return (
    <Box 
      sx={{ 
        display: 'flex', 
        flexDirection: 'column', 
        alignItems: 'center', 
        p: 3,
        minHeight: '500px',
        justifyContent: 'center',
        position: 'relative',
        perspective: '1000px'
      }}
    >
      {/* 3D Avatar Container */}
      <Box
        sx={{
          width: 280,
          height: 320,
          position: 'relative',
          transformStyle: 'preserve-3d',
          transform: `rotateX(${headRotation.x}deg) rotateY(${headRotation.y}deg)`,
          transition: 'transform 0.8s ease-out',
          animation: getFloatingAnimation(),
          '@keyframes idle-float': {
            '0%, 100%': { transform: 'translateY(0px) rotateX(0deg) rotateY(0deg)' },
            '50%': { transform: 'translateY(-8px) rotateX(2deg) rotateY(0deg)' }
          },
          '@keyframes thinking-float': {
            '0%, 100%': { transform: 'translateY(0px) rotateX(-5deg) rotateY(-10deg)' },
            '33%': { transform: 'translateY(-5px) rotateX(0deg) rotateY(5deg)' },
            '66%': { transform: 'translateY(-3px) rotateX(3deg) rotateY(-5deg)' }
          },
          '@keyframes speaking-bounce': {
            '0%, 100%': { transform: 'translateY(0px) scale(1)' },
            '50%': { transform: 'translateY(-3px) scale(1.02)' }
          },
          '@keyframes listening-glow': {
            '0%, 100%': { 
              transform: 'translateY(0px)',
              filter: 'drop-shadow(0 0 10px rgba(76, 175, 80, 0.3))'
            },
            '50%': { 
              transform: 'translateY(-5px)',
              filter: 'drop-shadow(0 0 20px rgba(76, 175, 80, 0.6))'
            }
          }
        }}
      >
        {/* Head - Main 3D Element */}
        <Box
          sx={{
            width: 160,
            height: 200,
            margin: '0 auto',
            position: 'relative',
            borderRadius: '50% 50% 50% 50% / 60% 60% 40% 40%',
            background: `linear-gradient(145deg, ${style.skinTone}, ${style.skinTone}dd)`,
            boxShadow: `
              inset -10px -10px 20px rgba(0,0,0,0.1),
              inset 10px 10px 20px rgba(255,255,255,0.3),
              0 20px 40px rgba(0,0,0,0.2)
            `,
            transform: 'translateZ(20px)',
            // Pawan Kalyan signature hairstyle - swept back with volume
            '&::before': {
              content: '""',
              position: 'absolute',
              top: '-30px',
              left: '10px',
              right: '10px',
              height: '50px',
              background: `linear-gradient(135deg, ${style.hairColor}, ${style.hairColor}cc, ${style.hairColor}dd)`,
              borderRadius: '45px 45px 30px 30px',
              boxShadow: 'inset 0 -10px 20px rgba(0,0,0,0.4), 0 8px 15px rgba(0,0,0,0.3)',
              transform: 'skewY(-2deg)' // Slight backward sweep
            },
            // Hair texture and volume
            '&::after': {
              content: '""',
              position: 'absolute',
              top: '-25px',
              left: '15px',
              right: '15px',
              height: '35px',
              background: `radial-gradient(ellipse, ${style.hairColor}dd, ${style.hairColor}88, transparent)`,
              borderRadius: '40px 40px 20px 20px',
              boxShadow: 'inset 0 -5px 12px rgba(0,0,0,0.3)'
            }
          }}
        >
          {/* Eyes */}
          <Box
            sx={{
              position: 'absolute',
              top: '35%',
              left: '25%',
              width: '15px',
              height: blinkState ? '2px' : '12px',
              background: 'white',
              borderRadius: '50%',
              boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.1)',
              transition: 'height 0.1s ease',
              transform: 'translateZ(5px)',
              '&::after': !blinkState ? {
                content: '""',
                position: 'absolute',
                top: '2px',
                left: '3px',
                width: '9px',
                height: '9px',
                background: style.eyeColor,
                borderRadius: '50%',
                boxShadow: 'inset 2px 2px 4px rgba(0,0,0,0.3)'
              } : {}
            }}
          />
          
          <Box
            sx={{
              position: 'absolute',
              top: '35%',
              right: '25%',
              width: '15px',
              height: blinkState ? '2px' : '12px',
              background: 'white',
              borderRadius: '50%',
              boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.1)',
              transition: 'height 0.1s ease',
              transform: 'translateZ(5px)',
              '&::after': !blinkState ? {
                content: '""',
                position: 'absolute',
                top: '2px',
                left: '3px',
                width: '9px',
                height: '9px',
                background: style.eyeColor,
                borderRadius: '50%',
                boxShadow: 'inset 2px 2px 4px rgba(0,0,0,0.3)'
              } : {}
            }}
          />

          {/* Pawan Kalyan signature thick eyebrows */}
          <Box
            sx={{
              position: 'absolute',
              top: '24%',
              left: '18%',
              width: '25px',
              height: '6px',
              background: `linear-gradient(90deg, ${style.hairColor}, ${style.hairColor}ee, ${style.hairColor}dd)`,
              borderRadius: '4px 2px 2px 4px',
              transform: `translateZ(4px) rotate(${eyebrowPosition - 3}deg) translateY(${eyebrowPosition}px)`,
              transition: 'transform 0.3s ease',
              boxShadow: '0 3px 6px rgba(0,0,0,0.4)'
            }}
          />
          
          <Box
            sx={{
              position: 'absolute',
              top: '24%',
              right: '18%',
              width: '25px',
              height: '6px',
              background: `linear-gradient(90deg, ${style.hairColor}dd, ${style.hairColor}ee, ${style.hairColor})`,
              borderRadius: '2px 4px 4px 2px',
              transform: `translateZ(4px) rotate(${-eyebrowPosition + 3}deg) translateY(${eyebrowPosition}px)`,
              transition: 'transform 0.3s ease',
              boxShadow: '0 3px 6px rgba(0,0,0,0.4)'
            }}
          />

          {/* Nose */}
          <Box
            sx={{
              position: 'absolute',
              top: '48%',
              left: '50%',
              transform: 'translateX(-50%) translateZ(8px)',
              width: '8px',
              height: '12px',
              background: `linear-gradient(145deg, ${style.skinTone}, ${style.skinTone}cc)`,
              borderRadius: '50% 50% 50% 50% / 30% 30% 70% 70%',
              boxShadow: '2px 2px 4px rgba(0,0,0,0.2)'
            }}
          />

          {/* Pawan Kalyan signature mustache */}
          <Box
            sx={{
              position: 'absolute',
              top: '60%',
              left: '35%',
              right: '35%',
              height: '4px',
              background: `linear-gradient(90deg, ${style.mustacheColor}dd, ${style.mustacheColor}, ${style.mustacheColor}dd)`,
              borderRadius: '2px',
              transform: 'translateZ(3px)',
              boxShadow: '0 2px 4px rgba(0,0,0,0.3)'
            }}
          />
          
          {/* Well-groomed beard */}
          <Box
            sx={{
              position: 'absolute',
              top: '68%',
              left: '25%',
              right: '25%',
              height: '20px',
              background: `radial-gradient(ellipse, ${style.beardColor}60, ${style.beardColor}40, transparent)`,
              borderRadius: '0 0 25px 25px',
              transform: 'translateZ(2px)'
            }}
          />
          
          {/* Modern Mouth */}
          <Box
            sx={{
              position: 'absolute',
              top: '65%',
              left: '50%',
              transform: 'translateX(-50%) translateZ(4px)',
              width: mouthState === 'open' ? '28px' : mouthState === 'half-open' ? '22px' : '20px',
              height: mouthState === 'open' ? '18px' : mouthState === 'half-open' ? '12px' : '5px',
              background: mouthState === 'smile' ? 'none' : mouthState === 'frown' ? 'none' : 'linear-gradient(145deg, #8B4513, #A0522D)',
              borderRadius: mouthState === 'smile' ? '0' : mouthState === 'frown' ? '0' : '50%',
              border: mouthState === 'smile' ? `3px solid ${style.accent}` : mouthState === 'frown' ? `3px solid #f44336` : 'none',
              borderTop: (mouthState === 'smile' || mouthState === 'frown') ? 'none' : undefined,
              borderRadius: mouthState === 'smile' ? '0 0 25px 25px' : mouthState === 'frown' ? '25px 25px 0 0' : '50%',
              transition: 'all 0.2s ease',
              boxShadow: mouthState !== 'smile' ? 'inset 0 3px 6px rgba(0,0,0,0.4), 0 1px 2px rgba(255,255,255,0.2)' : `0 2px 4px ${style.accent}40`
            }}
          />
          
          {/* Teeth when speaking */}
          {(mouthState === 'open' || mouthState === 'half-open') && (
            <Box
              sx={{
                position: 'absolute',
                top: '67%',
                left: '50%',
                transform: 'translateX(-50%) translateZ(5px)',
                width: '16px',
                height: '3px',
                background: 'white',
                borderRadius: '2px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.2)'
              }}
            />
          )}

          {/* Cheeks */}
          <Box
            sx={{
              position: 'absolute',
              top: '55%',
              left: '15%',
              width: '20px',
              height: '15px',
              background: 'rgba(255, 182, 193, 0.3)',
              borderRadius: '50%',
              transform: 'translateZ(2px)',
              opacity: isListening ? 1 : 0.5,
              transition: 'opacity 0.3s ease'
            }}
          />
          
          <Box
            sx={{
              position: 'absolute',
              top: '55%',
              right: '15%',
              width: '20px',
              height: '15px',
              background: 'rgba(255, 182, 193, 0.3)',
              borderRadius: '50%',
              transform: 'translateZ(2px)',
              opacity: isListening ? 1 : 0.5,
              transition: 'opacity 0.3s ease'
            }}
          />
        </Box>

        {/* Neck */}
        <Box
          sx={{
            width: '40px',
            height: '30px',
            background: style.skinTone,
            margin: '0 auto',
            borderRadius: '20px 20px 10px 10px',
            transform: 'translateZ(10px)',
            boxShadow: '0 5px 10px rgba(0,0,0,0.2)'
          }}
        />

        {/* Pawan Kalyan style white kurta/shirt */}
        <Box
          sx={{
            width: '150px',
            height: '80px',
            background: `linear-gradient(145deg, ${style.shirtColor}, #F8F8F8)`,
            margin: '0 auto',
            borderRadius: '75px 75px 30px 30px',
            transform: 'translateZ(10px)',
            boxShadow: '0 20px 40px rgba(0,0,0,0.3)',
            position: 'relative',
            border: `1px solid #E0E0E0`,
            // Kurta collar
            '&::before': {
              content: '""',
              position: 'absolute',
              top: '8px',
              left: '50%',
              transform: 'translateX(-50%)',
              width: '40px',
              height: '30px',
              background: 'linear-gradient(180deg, #F0F0F0, #FFFFFF)',
              borderRadius: '20px 20px 8px 8px',
              border: '1px solid #DDD',
              boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.05)'
            },
            // Traditional button details
            '&::after': {
              content: '""',
              position: 'absolute',
              top: '25px',
              left: '50%',
              transform: 'translateX(-50%)',
              width: '4px',
              height: '4px',
              background: style.accent,
              borderRadius: '50%',
              boxShadow: `0 8px 0 ${style.accent}, 0 16px 0 ${style.accent}`
            }
          }}
        />

        {/* Persona Badge */}
        <Box
          sx={{
            position: 'absolute',
            top: '-10px',
            right: '20px',
            width: '50px',
            height: '50px',
            borderRadius: '50%',
            background: `linear-gradient(145deg, ${style.accent}, ${style.accent}dd)`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '2rem',
            boxShadow: '0 8px 16px rgba(0,0,0,0.3)',
            border: '3px solid white',
            transform: 'translateZ(30px)',
            animation: isSpeaking ? 'badge-pulse 0.5s ease-in-out infinite alternate' : 'none',
            '@keyframes badge-pulse': {
              '0%': { transform: 'translateZ(30px) scale(1)' },
              '100%': { transform: 'translateZ(30px) scale(1.1)' }
            }
          }}
        >
          {PERSONAS[persona]?.icon || '🤖'}
        </Box>
      </Box>

      {/* Status and Info */}
      <Box sx={{ textAlign: 'center', mt: 3 }}>
        <Typography 
          variant="h4" 
          sx={{ 
            fontWeight: 'bold', 
            color: style.accent,
            mb: 0.5,
            textShadow: '0 3px 6px rgba(0,0,0,0.2)',
            fontFamily: 'serif'
          }}
        >
          {PERSONAS[persona]?.name || 'DevOps Leader'}
        </Typography>
        
        <Typography 
          variant="subtitle1" 
          sx={{ 
            color: style.accent,
            mb: 1,
            fontWeight: 'bold',
            fontSize: '1rem'
          }}
        >
          Tech Leader & Visionary
        </Typography>

        {/* Status Indicators */}
        {isThinking && (
          <Box sx={{ display: 'flex', justifyContent: 'center', gap: 0.5, mb: 2 }}>
            {[0, 1, 2].map((i) => (
              <Box
                key={i}
                sx={{
                  width: 12,
                  height: 12,
                  borderRadius: '50%',
                  background: `linear-gradient(145deg, ${style.accent}, ${style.accent}dd)`,
                  animation: `thinking-dots 1.5s ease-in-out ${i * 0.3}s infinite`,
                  boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                  '@keyframes thinking-dots': {
                    '0%, 80%, 100%': { 
                      opacity: 0.3, 
                      transform: 'scale(0.8) translateZ(0px)' 
                    },
                    '40%': { 
                      opacity: 1, 
                      transform: 'scale(1.2) translateZ(10px)' 
                    }
                  }
                }}
              />
            ))}
          </Box>
        )}

        {isSpeaking && (
          <Box sx={{ display: 'flex', justifyContent: 'center', gap: 1, mb: 2 }}>
            {[0, 1, 2, 3, 4].map((i) => (
              <Box
                key={i}
                sx={{
                  width: 4,
                  background: `linear-gradient(to top, ${style.accent}, ${style.accent}aa)`,
                  borderRadius: '2px',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                  animation: `sound-bars 0.6s ease-in-out ${i * 0.1}s infinite alternate`,
                  '@keyframes sound-bars': {
                    '0%': { height: '15px', opacity: 0.5 },
                    '100%': { height: '35px', opacity: 1 }
                  }
                }}
              />
            ))}
          </Box>
        )}

        <Box sx={{ 
          maxWidth: '350px',
          p: 3,
          bgcolor: `${style.accent}10`,
          borderRadius: 3,
          border: `2px solid ${style.accent}30`,
          boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
        }}>
          <Typography 
            variant="body1" 
            color="text.primary" 
            sx={{ 
              lineHeight: 1.5,
              fontSize: '1rem',
              fontWeight: '500',
              textAlign: 'center'
            }}
          >
            "Namaste! I'm here to guide you through your DevOps journey with the power of technology and innovation. Together, we'll build the future! 🚀"
          </Typography>
        </Box>
      </Box>
    </Box>
  );
}

export default Avatar3DRealistic;