interface WheelSliceTextProps {
  emoji: string;
  label: string;
  color: string;
  /** colore del testo: "#ffffff" o "#000000" */
  text: string;
  /** angolo (gradi, in senso orario dall'alto) del centro della fetta */
  midAngle: number;
  emojiSize?: number;
  labelSize?: number;
}

/** Spezza l'etichetta in al massimo due righe bilanciate (es. "JACKPOT +20" -> "JACKPOT" / "+20"). */
function splitLabel(label: string): string[] {
  const words = label.split(" ").filter(Boolean);
  if (words.length <= 1) return [label];
  const half = Math.ceil(words.length / 2);
  return [words.slice(0, half).join(" "), words.slice(half).join(" ")];
}

/**
 * Emoji + etichetta di una fetta di ruota (viewBox 400x400, centro 200,200).
 * - le fette sul lato destro leggono dal perno verso il bordo, quelle a sinistra dal bordo al perno:
 *   così il testo non risulta capovolto;
 * - contorno del testo per leggersi su qualsiasi colore;
 * - etichetta lontana dal perno centrale, emoji vicina al bordo.
 */
export function WheelSliceText({ emoji, label, text, midAngle, emojiSize = 34, labelSize = 16 }: WheelSliceTextProps) {
  const flip = midAngle > 0 && midAngle <= 180;
  const rot = flip ? -90 : 90;
  const emojiY = 42;
  const labelY = 92;
  const lines = splitLabel(label);
  return (
    <g transform={`rotate(${midAngle} 200 200)`}>
      <text
        x="200"
        y={emojiY}
        textAnchor="middle"
        dominantBaseline="central"
        fontSize={emojiSize}
        transform={`rotate(${rot} 200 ${emojiY})`}
      >
        {emoji}
      </text>
      <text
        x="200"
        y={labelY}
        textAnchor="middle"
        dominantBaseline="central"
        fill={text}
        stroke={text === "#ffffff" ? "#000000" : "#ffffff"}
        strokeOpacity="0.45"
        strokeWidth="3.5"
        paintOrder="stroke"
        fontSize={labelSize}
        fontWeight="900"
        transform={`rotate(${rot} 200 ${labelY})`}
      >
        {lines.map((line, i) => (
          <tspan key={i} x="200" dy={i === 0 ? (lines.length > 1 ? "-0.55em" : "0") : "1.15em"}>
            {line}
          </tspan>
        ))}
      </text>
    </g>
  );
}
