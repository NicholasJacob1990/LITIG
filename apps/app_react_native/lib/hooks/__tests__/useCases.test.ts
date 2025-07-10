import { renderHook, waitFor } from '@testing-library/react-native';
import { useQuery, useMutation } from '@tanstack/react-query';
import { useMyCases, useCreateCase, caseKeys } from '../useCases';

// Mock do TanStack Query
jest.mock('@tanstack/react-query');

const mockUseQuery = useQuery as jest.MockedFunction<typeof useQuery>;
const mockUseMutation = useMutation as jest.MockedFunction<typeof useMutation>;

describe('useCases hooks', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useMyCases', () => {
    it('deve retornar dados dos casos do usuário', async () => {
      const mockCases = [
        {
          id: '1',
          title: 'Caso Teste',
          status: 'in_progress',
          created_at: '2024-01-01T00:00:00Z',
        },
      ];

      mockUseQuery.mockReturnValue({
        data: mockCases,
        isLoading: false,
        error: null,
        refetch: jest.fn(),
      } as any);

      const { result } = renderHook(() => useMyCases());

      expect(result.current.data).toEqual(mockCases);
      expect(result.current.isLoading).toBe(false);
      expect(mockUseQuery).toHaveBeenCalledWith({
        queryKey: ['my-cases'],
        queryFn: expect.any(Function),
        staleTime: 60000, // 1 minuto
        gcTime: 300000, // 5 minutos
      });
    });

    it('deve lidar com estado de loading', () => {
      mockUseQuery.mockReturnValue({
        data: undefined,
        isLoading: true,
        error: null,
        refetch: jest.fn(),
      } as any);

      const { result } = renderHook(() => useMyCases());

      expect(result.current.isLoading).toBe(true);
      expect(result.current.data).toBeUndefined();
    });

    it('deve lidar com erros', () => {
      const mockError = new Error('Erro ao buscar casos');
      
      mockUseQuery.mockReturnValue({
        data: undefined,
        isLoading: false,
        error: mockError,
        refetch: jest.fn(),
      } as any);

      const { result } = renderHook(() => useMyCases());

      expect(result.current.error).toBe(mockError);
      expect(result.current.data).toBeUndefined();
    });
  });

  describe('useCreateCase', () => {
    it('deve configurar mutation para criação de caso', () => {
      const mockMutate = jest.fn();
      const mockQueryClient = {
        invalidateQueries: jest.fn(),
        setQueryData: jest.fn(),
      };

      mockUseMutation.mockReturnValue({
        mutate: mockMutate,
        isLoading: false,
        error: null,
      } as any);

      const { result } = renderHook(() => useCreateCase());

      expect(mockUseMutation).toHaveBeenCalledWith({
        mutationFn: expect.any(Function),
        onSuccess: expect.any(Function),
      });
    });
  });

  describe('caseKeys', () => {
    it('deve gerar chaves de query corretas', () => {
      expect(caseKeys.all).toEqual(['cases']);
      expect(caseKeys.lists()).toEqual(['cases', 'list']);
      expect(caseKeys.list({ status: 'active' })).toEqual(['cases', 'list', { status: 'active' }]);
      expect(caseKeys.detail('123')).toEqual(['cases', 'detail', '123']);
    });
  });
});
