import { createElement } from 'lwc';
import Editor from 'c/fsc_EditarDocumentoLegal';
import getDocumentoLegalEditable from '@salesforce/apex/FSC_RlaAccionesController.getDocumentoLegalEditable';
import guardarDocumentoLegalEditado from '@salesforce/apex/FSC_RlaAccionesController.guardarDocumentoLegalEditado';

jest.mock('@salesforce/apex/FSC_RlaAccionesController.getDocumentoLegalEditable', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/FSC_RlaAccionesController.guardarDocumentoLegalEditado', () => ({ default: jest.fn() }), { virtual: true });

const data = {
    bloques: [
        { clave: 't0', texto: 'Título del documento', parrafo: 1 },
        { clave: 't1', texto: 'Primera cláusula', parrafo: 2 },
        { clave: 't2', texto: 'Nombre del firmante', parrafo: 3 }
    ]
};

const flush = async () => { await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); };
const mount = async (type = 'PAGARE') => {
    const element = createElement('c-fsc_-editar-documento-legal', { is: Editor });
    element.recordId = 'rla-id';
    element.contentVersionId = 'version-id';
    element.tipoDocumento = type;
    document.body.appendChild(element);
    await flush();
    return element;
};
const button = (element, label) => [...element.shadowRoot.querySelectorAll('lightning-button')].find((item) => item.label === label);
const change = (element, value) => {
    const input = element.shadowRoot.querySelector('[data-key="t1"]');
    input.value = value;
    input.dispatchEvent(new CustomEvent('input'));
};

describe('editor de documentos legales', () => {
    beforeEach(() => {
        getDocumentoLegalEditable.mockResolvedValue(data);
        guardarDocumentoLegalEditado.mockResolvedValue('version-nueva');
    });
    afterEach(() => {
        while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
        jest.clearAllMocks();
    });

    it('muestra todo el texto separado y no expone imágenes', async () => {
        const element = await mount();
        expect(element.shadowRoot.querySelector('h2').textContent).toBe('Editar pagaré');
        expect(element.shadowRoot.querySelectorAll('textarea')).toHaveLength(3);
        expect(element.shadowRoot.querySelectorAll('.textSection')).toHaveLength(3);
        expect(element.shadowRoot.querySelectorAll('img')).toHaveLength(0);
        expect(getDocumentoLegalEditable).toHaveBeenCalledWith({ residentialLoanApplicationId: 'rla-id', contentVersionId: 'version-id' });
    });

    it('envía solamente los textos modificados y avisa al componente padre', async () => {
        const element = await mount('CONTRATO');
        const saved = jest.fn();
        element.addEventListener('saved', saved);
        change(element, 'Cláusula editada');
        button(element, 'Guardar').click();
        await flush();
        expect(element.shadowRoot.querySelector('h2').textContent).toBe('Editar contrato');
        expect(guardarDocumentoLegalEditado).toHaveBeenCalledWith({
            residentialLoanApplicationId: 'rla-id', contentVersionId: 'version-id', cambiosJson: '{"t1":"Cláusula editada"}'
        });
        expect(saved).toHaveBeenCalledTimes(1);
        expect(saved.mock.calls[0][0].detail.versionId).toBe('version-nueva');
    });

    it('cancelar cierra sin guardar', async () => {
        const element = await mount();
        const cancel = jest.fn();
        element.addEventListener('cancel', cancel);
        change(element, 'Cambio descartado');
        button(element, 'Cancelar').click();
        expect(cancel).toHaveBeenCalledTimes(1);
        expect(guardarDocumentoLegalEditado).not.toHaveBeenCalled();
    });

    it('volver al texto original no reemplaza el archivo', async () => {
        const element = await mount();
        change(element, 'Cambio');
        change(element, 'Primera cláusula');
        button(element, 'Guardar').click();
        await flush();
        expect(guardarDocumentoLegalEditado).not.toHaveBeenCalled();
    });

    it('conserva abierto el editor cuando el guardado falla', async () => {
        guardarDocumentoLegalEditado.mockRejectedValue({ body: { message: 'El archivo anterior se conserva.' } });
        const element = await mount();
        const saved = jest.fn();
        element.addEventListener('saved', saved);
        change(element, 'Nuevo texto');
        button(element, 'Guardar').click();
        await flush();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('El archivo anterior se conserva.');
        expect(saved).not.toHaveBeenCalled();
        expect(button(element, 'Guardar').disabled).toBe(false);
    });

    it('muestra el error y bloquea guardar si el documento no se pudo cargar', async () => {
        getDocumentoLegalEditable.mockRejectedValue({ body: { message: 'Documento no disponible' } });
        const element = await mount();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('Documento no disponible');
        expect(button(element, 'Guardar').disabled).toBe(true);
    });
});
