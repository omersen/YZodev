import React, { useState } from 'react';
import { AgendaDay } from '../types';
import { agendaData } from '../data/content';

export const Agenda: React.FC = () => {
    const [activeTab, setActiveTab] = useState<string>('day1');
    const currentDay = agendaData[activeTab];

    return (
        <div className="bg-white p-6 rounded-xl shadow-sm border border-stone-200">
            {/* Tabs */}
            <div className="flex border-b border-stone-200 mb-6 overflow-x-auto">
                {Object.values(agendaData).map((day) => (
                    <button
                        key={day.id}
                        onClick={() => setActiveTab(day.id)}
                        className={`px-6 py-3 text-sm md:text-base font-medium whitespace-nowrap transition-colors duration-200 focus:outline-none ${
                            activeTab === day.id
                                ? 'border-b-2 border-teal-600 text-teal-700'
                                : 'text-stone-500 hover:text-stone-800'
                        }`}
                    >
                        {day.title}
                    </button>
                ))}
            </div>

            {/* Content */}
            <div className="animate-fade-in">
                <div className="flex items-center mb-6">
                    <div className="w-12 h-12 rounded-full bg-stone-100 flex items-center justify-center mr-4 shrink-0">
                        <i className={`fas ${currentDay.icon} ${currentDay.color} text-2xl`}></i>
                    </div>
                    <div>
                        <h3 className="text-2xl font-bold text-stone-800">{currentDay.title}</h3>
                        <p className="text-stone-500 text-sm font-medium">🎯 Hedef: {currentDay.goal}</p>
                    </div>
                </div>

                <div className="space-y-3">
                    {currentDay.sessions.map((session, idx) => (
                        <div key={idx} className="flex flex-col md:flex-row border-l-4 border-stone-200 pl-4 py-3 hover:border-teal-500 hover:bg-stone-50 transition-all duration-300 rounded-r-lg">
                            <div className="md:w-32 font-bold text-teal-600 text-sm mb-1 md:mb-0 shrink-0">
                                {session.time}
                            </div>
                            <div>
                                <h4 className="font-bold text-stone-800">{session.title}</h4>
                                <p className="text-sm text-stone-600">{session.desc}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};