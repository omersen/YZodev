import React from 'react';
import { Radar, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, ResponsiveContainer, PieChart, Pie, Cell, Legend, Tooltip } from 'recharts';

export const ModelRadarChart: React.FC = () => {
    // Updated to 7 Dimensions from the text
    const data = [
        { subject: '1. Bilişsel Derinlik', A: 5, B: 2, fullMark: 5 },
        { subject: '2. Otantiklik', A: 5, B: 1, fullMark: 5 },
        { subject: '3. Süreç Şeffaflığı', A: 5, B: 1, fullMark: 5 },
        { subject: '4. YZ Etiği', A: 5, B: 0, fullMark: 5 },
        { subject: '5. Çoklu Kanıt', A: 5, B: 2, fullMark: 5 },
        { subject: '6. İşbirliği', A: 4, B: 1, fullMark: 5 },
        { subject: '7. Yansıtma', A: 5, B: 1, fullMark: 5 },
    ];

    return (
        <div className="w-full h-[320px] md:h-[380px]">
            <ResponsiveContainer width="100%" height="100%">
                <RadarChart cx="50%" cy="50%" outerRadius="70%" data={data}>
                    <PolarGrid stroke="#e7e5e4" />
                    <PolarAngleAxis dataKey="subject" tick={{ fill: '#44403c', fontSize: 11, fontWeight: 500 }} />
                    <PolarRadiusAxis angle={30} domain={[0, 5]} tick={false} axisLine={false} />
                    <Radar
                        name="İdeal Nitelikli Ödev"
                        dataKey="A"
                        stroke="#0d9488"
                        strokeWidth={2}
                        fill="#0d9488"
                        fillOpacity={0.4}
                    />
                    <Radar
                        name="Geleneksel Ödev"
                        dataKey="B"
                        stroke="#a8a29e"
                        strokeWidth={2}
                        fill="#a8a29e"
                        fillOpacity={0.2}
                    />
                    <Legend wrapperStyle={{ paddingTop: '10px' }}/>
                    <Tooltip 
                        contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e7e5e4' }}
                        itemStyle={{ fontSize: '12px' }}
                    />
                </RadarChart>
            </ResponsiveContainer>
        </div>
    );
};

export const ParadigmShiftChart: React.FC = () => {
    const data = [
        { name: 'Süreç Odaklı (Yeni)', value: 70 },
        { name: 'Sonuç Odaklı (Eski)', value: 30 },
    ];
    const COLORS = ['#0d9488', '#e7e5e4'];

    return (
        <div className="w-full h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                    <Pie
                        data={data}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        fill="#8884d8"
                        paddingAngle={5}
                        dataKey="value"
                    >
                        {data.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                    </Pie>
                    <Tooltip />
                    <Legend verticalAlign="bottom" height={36}/>
                </PieChart>
            </ResponsiveContainer>
        </div>
    );
};