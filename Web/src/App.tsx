import React, { useState, useEffect, useRef, useCallback } from 'react';
import './App.css';

interface AssistantResult {
  id: string;
  name: string;
  response: string;
  timestamp: number;
  uuid: string; // Stable unique identifier
  provider: string;
}

interface Advisor {
  name: string;
  title: string;
  emoji: string;
  position: { x: number; y: number }; // Position in the semicircle
}

interface CouncilState {
  results: AssistantResult[];
  transcript: string;
  summary: string;
  currentRound: number | null;
  roundTitle: string;
  isComplete: boolean;
}

// Function to get provider favicon URL
const getProviderFavicon = (provider: string): string => {
  switch (provider.toLowerCase()) {
    case 'openai': return 'https://openai.com/favicon.ico';
    case 'anthropic': return 'https://claude.ai/favicon.ico';
    case 'gemini': return 'https://www.gstatic.com/lamda/images/gemini_sparkle_4g_512_lt_f94943af3be039176192d.png';
    case 'perplexity': return 'https://perplexity.ai/favicon.ico';
    case 'mistral': return 'https://mistral.ai/favicon.ico';
    default: return '';
  }
};

// Define all advisors with their fixed positions in a wider semicircle
const ADVISORS: Advisor[] = [
  { name: "Zafir", title: "the Scheming Vizier", emoji: "⚔️", position: { x: 5, y: 85 } },
  { name: "Malik", title: "the Grand Treasurer", emoji: "💰", position: { x: 20, y: 80 } },
  { name: "Lorenzo", title: "the Court Philosopher", emoji: "📚", position: { x: 35, y: 75 } },
  { name: "Farid", title: "the Spymaster", emoji: "👁️", position: { x: 65, y: 75 } },
  { name: "Edmund", title: "the War Strategist", emoji: "⚔️", position: { x: 80, y: 80 } },
  { name: "Benedict", title: "the Trade Minister", emoji: "📦", position: { x: 95, y: 85 } },
  { name: "Godwin", title: "the Peacemaker", emoji: "🕊️", position: { x: 90, y: 45 } },
  { name: "Marcus", title: "the Traditionalist", emoji: "📜", position: { x: 75, y: 15 } },
  { name: "Rodrigo", title: "the Court Gossip", emoji: "💬", position: { x: 55, y: 5 } },
  { name: "Alistair", title: "the Mystic", emoji: "🔮", position: { x: 45, y: 5 } },
  { name: "Saeed", title: "the Contrarian", emoji: "🌪️", position: { x: 25, y: 15 } },
  { name: "Abbas", title: "the Silent Observer", emoji: "🤫", position: { x: 10, y: 45 } }
];

function App() {
  const [query, setQuery] = useState('');
  const [councilState, setCouncilState] = useState<CouncilState>({
    results: [],
    transcript: '',
    summary: '',
    currentRound: null,
    roundTitle: '',
    isComplete: false
  });
  const [loading, setLoading] = useState(false);
  const [connectionError, setConnectionError] = useState<string | null>(null);
  const [showTranscript, setShowTranscript] = useState(false);
  const [gridColumns, setGridColumns] = useState(4);
  const eventSourceRef = useRef<EventSource | null>(null);
  const gridRef = useRef<HTMLDivElement>(null);

  // Calculate dynamic grid columns based on container width
  const calculateGridColumns = useCallback(() => {
    if (!gridRef.current) return;
    
    const containerWidth = gridRef.current.offsetWidth;
    const padding = window.innerWidth <= 480 ? 24 : window.innerWidth <= 768 ? 30 : 40;
    const availableWidth = containerWidth - padding;
    
    // iOS-style calculation: adaptive min width based on screen size
    const minCardWidth = window.innerWidth <= 480 ? 250 : window.innerWidth <= 768 ? 260 : 280;
    const maxColumns = Math.max(1, Math.floor(availableWidth / minCardWidth));
    const columns = Math.min(maxColumns, 4);
    
    setGridColumns(columns);
  }, []);

  // Handle window resize
  useEffect(() => {
    calculateGridColumns();
    
    const handleResize = () => {
      requestAnimationFrame(calculateGridColumns);
    };
    
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [calculateGridColumns]);

  // Recalculate when results section becomes visible
  useEffect(() => {
    if (councilState.results.length > 0) {
      // Small delay to ensure DOM is updated
      setTimeout(calculateGridColumns, 100);
    }
  }, [councilState.results.length, calculateGridColumns]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim() || loading) return;

    // Reset state
    setCouncilState({
      results: [],
      transcript: '',
      summary: '',
      currentRound: null,
      roundTitle: '',
      isComplete: false
    });

    setLoading(true);
    setConnectionError(null);

    // Close existing connection
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    // Start streaming
    const encodedQuery = encodeURIComponent(query);
    const eventSource = new EventSource(`/stream/council?query=${encodedQuery}`);
    eventSourceRef.current = eventSource;

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        
        switch (data.type) {
          case 'roundStarted':
            setCouncilState(prev => ({
              ...prev,
              currentRound: data.data.roundNumber,
              roundTitle: data.data.title
            }));
            break;
            
          case 'advisorResponse':
            setCouncilState(prev => ({
              ...prev,
              results: [...prev.results, {
                id: data.data.advisorName,
                name: data.data.advisorName,
                response: data.data.statement,
                timestamp: Date.now(),
                uuid: crypto.randomUUID(), // Generate stable UUID
                provider: data.data.provider
              }] // Append new items for chronological order
            }));
            break;
            
          case 'roundCompleted':
            // Round completed, just update UI
            break;
            
          case 'transcriptGenerated':
            setCouncilState(prev => ({
              ...prev,
              transcript: data.data.transcript
            }));
            break;
            
          case 'summaryGenerated':
            setCouncilState(prev => ({
              ...prev,
              summary: data.data.summary
            }));
            break;
            
          case 'sessionCompleted':
            setCouncilState(prev => ({
              ...prev,
              isComplete: true
            }));
            setLoading(false);
            eventSource.close();
            break;
        }
      } catch (error) {
        console.error('Error parsing stream data:', error);
      }
    };

    eventSource.onerror = (error) => {
      console.error('EventSource error:', error);
      console.error('Connection state:', eventSource.readyState);
      
      // More detailed error handling for SSL issues
      if (eventSource.readyState === EventSource.CLOSED) {
        console.error('EventSource connection was closed by the server');
        setConnectionError('Connection lost. This may be due to SSL configuration. Please try again.');
      } else if (eventSource.readyState === EventSource.CONNECTING) {
        console.error('EventSource is still trying to connect');
        // Don't immediately set loading to false if still connecting
        return;
      } else {
        setConnectionError('Failed to establish live connection. Check your network and SSL settings.');
      }
      
      setLoading(false);
      eventSource.close();
    };
  };

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
    };
  }, []);

  return (
    <div className="App">
      <div className="container">
        <h1>The Eunuch Council</h1>
        
        <div className={`top-section ${councilState.summary ? 'has-summary' : ''}`}>
          <form onSubmit={handleSubmit} className="query-form compact">
            <div className="query-input-group">
              <textarea
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    if (!loading && query.trim()) {
                      handleSubmit(e);
                    }
                  }
                }}
                placeholder="Enter your question here..."
                rows={2}
                className="query-input"
              />
              <button type="submit" disabled={loading || !query.trim()} className="convene-button">
                {loading ? 'Convening...' : 'Convene'}
              </button>
            </div>
            
            {/* Integrated Status View */}
            {loading && councilState.currentRound && (
              <div className="integrated-status">
                <div className="status-header">
                  <span className="round-info">🏛️ Round {councilState.currentRound}: {councilState.roundTitle}</span>
                  <span className="advisor-count">{councilState.results.length} advisors have spoken</span>
                </div>
              </div>
            )}
          </form>
          
          {councilState.summary && (
            <div className="council-summary">
              <h3>Abbas speaks:</h3>
              <div className="summary-text">{councilState.summary}</div>
            </div>
          )}
        </div>

        {connectionError && (
          <div className="connection-error" style={{
            background: '#fee2e2',
            border: '1px solid #fca5a5',
            borderRadius: '8px',
            padding: '12px',
            margin: '16px 0',
            color: '#991b1b'
          }}>
            <strong>⚠️ Connection Error:</strong> {connectionError}
          </div>
        )}


        {/* Transcript Button */}
        {councilState.transcript && (
          <div className="transcript-button-container">
            <button 
              onClick={() => setShowTranscript(true)}
              className="transcript-button"
            >
              📜 View Transcript
            </button>
          </div>
        )}

        {/* Advisor Grid */}
        {councilState.results.length > 0 && (
          <div 
            ref={gridRef}
            className="advisor-grid"
            style={{ gridTemplateColumns: `repeat(${gridColumns}, 1fr)` }}
          >
            {ADVISORS.map((advisor) => {
              const result = councilState.results.find(r => r.name === advisor.name);
              const hasSpoken = result !== undefined;
              
              return (
                <div
                  key={advisor.name}
                  className={`advisor-card ${hasSpoken ? 'has-spoken' : 'waiting'}`}
                >
                  <div className="advisor-header">
                    <div className="advisor-info">
                      <div className="advisor-name-line">
                        <span className="advisor-name">{advisor.name}</span>
                        {result && (
                          <span className="timestamp">
                            {new Date(result.timestamp).toLocaleTimeString()}
                          </span>
                        )}
                      </div>
                    </div>
                    {result && getProviderFavicon(result.provider) && (
                      <img 
                        src={getProviderFavicon(result.provider)} 
                        alt={`${result.provider} icon`}
                        className="provider-favicon" 
                        title={`Powered by ${result.provider}`}
                      />
                    )}
                  </div>
                  
                  <div className="advisor-content">
                    {result ? (
                      <div className="response-text-container">
                        <div className="response-text">{result.response}</div>
                      </div>
                    ) : (
                      <div className="waiting-message">Awaiting counsel...</div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Transcript Modal */}
        {showTranscript && (
          <div className="transcript-modal-overlay" onClick={() => setShowTranscript(false)}>
            <div className="transcript-modal" onClick={(e) => e.stopPropagation()}>
              <div className="transcript-modal-header">
                <h3>Council Transcript</h3>
                <button 
                  onClick={() => setShowTranscript(false)}
                  className="transcript-close-button"
                >
                  ✕
                </button>
              </div>
              <div className="transcript-modal-content">
                <pre>{councilState.transcript}</pre>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
