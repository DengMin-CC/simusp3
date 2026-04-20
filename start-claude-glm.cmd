@echo off                                                                                                             
  cd /d "%~dp0"                                                                                                         
                                                                                                                        
  set ANTHROPIC_API_KEY=70ed045258154230a69d3be0f3398df6.k8E2cdHlDZN1U6uV                                               
  set ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/llm-adaptor/v4                                                    
  set CLAUDE_CODE_USE_BEDROCK=0                                                                                         
  set CLAUDE_CODE_USE_VERTEX=0                                                                                          
  set CLAUDE_CODE_USE_FOUNDRY=0                                                                                         
                                                                                                                        
  echo ========================================                                                                         
  echo   Claude Code + GLM Model                                                                                        
  echo   Working Dir: %CD%                                                                                              
  echo ========================================                                                                         
  echo.                                                                                                                 
                                                                                                                        
  claude --bare --model glm-5-turbo                                                                                     
  pause