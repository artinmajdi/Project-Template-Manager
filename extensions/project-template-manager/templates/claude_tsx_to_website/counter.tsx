import { useState } from 'react';

const Counter = () => {
  const [count, setCount] = useState(0);

  return (
    <div className="p-6 max-w-sm mx-auto bg-white rounded-xl shadow-md flex flex-col items-center">
      <h2 className="text-xl font-bold mb-4">Interactive Counter</h2>
      <p className="text-3xl font-bold mb-4">{count}</p>
      <div className="flex space-x-4">
        <button
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          onClick={() => setCount(count - 1)}
        >
          Decrease
        </button>
        <button
          className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
          onClick={() => setCount(count + 1)}
        >
          Increase
        </button>
      </div>
    </div>
  );
};

export default Counter;
