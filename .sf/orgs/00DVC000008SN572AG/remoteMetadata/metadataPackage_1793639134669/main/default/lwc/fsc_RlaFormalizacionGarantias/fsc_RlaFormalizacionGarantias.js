import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import getContexto from '@salesforce/apex/FSC_FormalizacionGarantiasController.getContexto';
import ejecutarAccion from '@salesforce/apex/FSC_FormalizacionGarantiasController.ejecutarAccion';
import descartarArchivos from '@salesforce/apex/FSC_FormalizacionGarantiasController.descartarArchivos';
import getDatosDocumento from '@salesforce/apex/FSC_FormalizacionGarantiasController.getDatosDocumento';
import generarDocumento from '@salesforce/apex/FSC_FormalizacionGarantiasController.generarDocumento';

const FORMATOS_ARCHIVO = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.jpg', '.jpeg', '.png'];
const TIPO_INVENTARIO = 'inventario';
const TIPO_AUTORIZACION = 'autorizacion';
const OPCIONES_TRATAMIENTO_PROPIETARIO = ['del señor', 'de la señora', 'de la empresa'].map((valor) => ({ label: valor, value: valor }));
const OPCIONES_SEXO = ['Masculino', 'Femenino'].map((valor) => ({ label: valor, value: valor }));

export default class FscRlaFormalizacionGarantias extends NavigationMixin(LightningElement) {
	@api recordId;

	contexto;
	cargando = false;
	conectado = false;
	mostrarDatosGarantia = false;

	accionActual;
	valores = {};
	archivos = [];

	tipoDocumento;
	documento;

	_etapa;
	_subestado;

	// El panel se recarga cuando el registro cambia de etapa o subestado por otras acciones.
	@api
	get etapa() {
		return this._etapa;
	}
	set etapa(valor) {
		const cambio = valor !== this._etapa;
		this._etapa = valor;
		if (cambio && this.conectado) {
			this.cargar();
		}
	}

	@api
	get subestado() {
		return this._subestado;
	}
	set subestado(valor) {
		const cambio = valor !== this._subestado;
		this._subestado = valor;
		if (cambio && this.conectado) {
			this.cargar();
		}
	}

	connectedCallback() {
		this.conectado = true;
		this.cargar();
	}

	async cargar() {
		if (!this.recordId) {
			return;
		}
		try {
			this.contexto = await getContexto({ residentialLoanApplicationId: this.recordId });
		} catch (error) {
			this.contexto = undefined;
		}
	}

	// ===== Vista =====

	get mostrar() {
		return this.contexto?.visible === true;
	}

	get modalidad() {
		return this.contexto?.garantia?.modalidad;
	}

	get acciones() {
		return this.contexto?.acciones || [];
	}

	get tieneAcciones() {
		return this.acciones.length > 0 || this.contexto?.puedeGenerarInventario || this.contexto?.puedeGenerarAutorizacion;
	}

	get tieneDatosGarantia() {
		return (this.contexto?.datosGarantia || []).length > 0;
	}

	get tieneEnlaces() {
		return (this.contexto?.enlaces || []).length > 0;
	}

	get etiquetaDatosGarantia() {
		return this.mostrarDatosGarantia ? 'Ocultar datos de la garantía' : 'Ver datos de la garantía';
	}

	get resumenGarantia() {
		const garantia = this.contexto?.garantia;
		if (!garantia) {
			return [];
		}
		return [
			{ etiqueta: 'Modalidad', valor: garantia.modalidad },
			{ etiqueta: 'N.º expediente Registro de Títulos', valor: garantia.numeroExpedienteRegistroTitulos },
			{ etiqueta: 'N.º expediente DGII', valor: garantia.numeroExpedienteDgii },
			{ etiqueta: 'Fecha de constitución', valor: this.formatearFecha(garantia.fechaConstitucion) },
			{ etiqueta: 'Fecha de formalización', valor: this.formatearFecha(garantia.fechaFormalizacion) },
		].filter((dato) => dato.valor);
	}

	toggleDatosGarantia() {
		this.mostrarDatosGarantia = !this.mostrarDatosGarantia;
	}

	abrirEnlace(event) {
		window.open(event.currentTarget.dataset.url, '_blank', 'noopener');
	}

	// ===== Acciones =====

	get mostrarModalAccion() {
		return Boolean(this.accionActual);
	}

	get camposAccion() {
		return (this.accionActual?.campos || []).map((campo) => ({
			...campo,
			valorActual: this.valores[campo.nombre],
			esCombobox: campo.tipo === 'combobox',
			esTexto: campo.tipo === 'text',
			esFecha: campo.tipo === 'date',
			esAreaTexto: campo.tipo === 'textarea',
			esArchivos: campo.tipo === 'archivos',
		}));
	}

	get formatosArchivo() {
		return FORMATOS_ARCHIVO;
	}

	get hoy() {
		const fecha = new Date();
		const mes = String(fecha.getMonth() + 1).padStart(2, '0');
		const dia = String(fecha.getDate()).padStart(2, '0');
		return `${fecha.getFullYear()}-${mes}-${dia}`;
	}

	abrirAccion(event) {
		const codigo = event.currentTarget.dataset.codigo;
		const accion = this.acciones.find((item) => item.codigo === codigo);
		if (!accion) {
			return;
		}
		const valores = {};
		(accion.campos || []).forEach((campo) => {
			if (campo.valor) {
				valores[campo.nombre] = campo.valor;
			}
		});
		this.valores = valores;
		this.archivos = [];
		if (!accion.campos || accion.campos.length === 0) {
			this.confirmarSinCampos(accion);
			return;
		}
		this.accionActual = accion;
	}

	async confirmarSinCampos(accion) {
		const confirmado = await LightningConfirm.open({
			message: `¿Confirma la acción "${accion.etiqueta}"?`,
			label: 'Formalización de garantía',
			theme: 'default',
		});
		if (!confirmado) {
			return;
		}
		this.accionActual = accion;
		await this.enviarAccion();
	}

	handleCampoAccion(event) {
		const nombre = event.target.dataset.campo;
		this.valores = { ...this.valores, [nombre]: event.detail.value };
	}

	handleArchivosCargados(event) {
		const cargados = (event.detail.files || []).map((archivo) => ({ id: archivo.documentId, nombre: archivo.name }));
		this.archivos = [...this.archivos, ...cargados];
	}

	async quitarArchivo(event) {
		const id = event.currentTarget.dataset.id;
		try {
			await descartarArchivos({ documentosIds: [id] });
		} catch (error) {
			// El archivo puede haberse descartado antes; se quita igual de la lista.
		}
		this.archivos = this.archivos.filter((archivo) => archivo.id !== id);
	}

	async cerrarModalAccion() {
		const pendientes = this.archivos.map((archivo) => archivo.id);
		this.accionActual = undefined;
		this.archivos = [];
		if (pendientes.length > 0) {
			try {
				await descartarArchivos({ documentosIds: pendientes });
			} catch (error) {
				// Sin vínculo con la solicitud, el archivo queda solo en la biblioteca del usuario.
			}
		}
	}

	async enviarAccion() {
		const entradas = [...this.template.querySelectorAll('[data-campo]')];
		const validas = entradas.reduce((ok, entrada) => (entrada.reportValidity ? entrada.reportValidity() && ok : ok), true);
		if (!validas) {
			return;
		}
		const faltaArchivo = (this.accionActual.campos || []).some((campo) => campo.tipo === 'archivos' && campo.requerido && this.archivos.length === 0);
		if (faltaArchivo) {
			this.toast('Archivo requerido', 'Debe cargar al menos un archivo para continuar.', 'warning');
			return;
		}

		this.cargando = true;
		try {
			await ejecutarAccion({
				residentialLoanApplicationId: this.recordId,
				accion: this.accionActual.codigo,
				datos: { ...this.valores, archivos: this.archivos.map((archivo) => archivo.id) },
			});
			this.toast('Actualizado', `${this.accionActual.etiqueta}: acción registrada.`, 'success');
			this.accionActual = undefined;
			this.archivos = [];
			await this.cargar();
			this.dispatchEvent(new CustomEvent('actualizado'));
		} catch (error) {
			this.toast('Error', this.mensajeError(error, 'No se pudo registrar la acción.'), 'error');
		} finally {
			this.cargando = false;
		}
	}

	// ===== Documentos =====

	get mostrarModalDocumento() {
		return Boolean(this.documento);
	}

	get esInventario() {
		return this.tipoDocumento === TIPO_INVENTARIO;
	}

	get esAutorizacion() {
		return this.tipoDocumento === TIPO_AUTORIZACION;
	}

	get tituloDocumento() {
		return this.esInventario ? 'Inventario para depósito en Registro de Títulos' : 'Autorización de oposición y entrega de matrícula';
	}

	get opcionesTratamientoPropietario() {
		return OPCIONES_TRATAMIENTO_PROPIETARIO;
	}

	get opcionesSexo() {
		return OPCIONES_SEXO;
	}

	get documentosInventario() {
		return (this.documento?.documentos || []).map((fila, indice) => ({ ...fila, indice, clave: `doc-${indice}` }));
	}

	get tasasInventario() {
		return (this.documento?.tasas || []).map((fila, indice) => ({
			...fila,
			indice,
			clave: `tasa-${indice}`,
			precio: this.formatearMonto(this.numero(fila.cantidad) * this.numero(fila.valor)),
		}));
	}

	get totalInventario() {
		const total = (this.documento?.tasas || []).reduce((suma, fila) => suma + this.numero(fila.cantidad) * this.numero(fila.valor), 0);
		return this.formatearMonto(total);
	}

	async abrirInventario() {
		await this.abrirDocumento(TIPO_INVENTARIO);
	}

	async abrirAutorizacion() {
		await this.abrirDocumento(TIPO_AUTORIZACION);
	}

	async abrirDocumento(tipo) {
		this.cargando = true;
		try {
			const datos = await getDatosDocumento({ residentialLoanApplicationId: this.recordId, tipo });
			this.tipoDocumento = tipo;
			this.documento = JSON.parse(JSON.stringify(datos));
		} catch (error) {
			this.toast('Error', this.mensajeError(error, 'No se pudieron cargar los datos del documento.'), 'error');
		} finally {
			this.cargando = false;
		}
	}

	cerrarModalDocumento() {
		this.documento = undefined;
		this.tipoDocumento = undefined;
	}

	handleCampoDocumento(event) {
		const nombre = event.target.dataset.campo;
		this.documento = { ...this.documento, [nombre]: event.detail.value };
	}

	handleFilaDocumento(event) {
		const { lista, indice, propiedad } = event.target.dataset;
		const filas = [...this.documento[lista]];
		filas[Number(indice)] = { ...filas[Number(indice)], [propiedad]: event.detail.value };
		this.documento = { ...this.documento, [lista]: filas };
	}

	async generar() {
		const entradas = [...this.template.querySelectorAll('[data-documento]')];
		const validas = entradas.reduce((ok, entrada) => (entrada.reportValidity ? entrada.reportValidity() && ok : ok), true);
		if (!validas) {
			return;
		}
		this.cargando = true;
		try {
			const documentoId = await generarDocumento({
				residentialLoanApplicationId: this.recordId,
				tipo: this.tipoDocumento,
				datosJson: JSON.stringify(this.documento),
			});
			this.toast('Documento generado', 'El PDF quedó en los Archivos de la solicitud.', 'success');
			this.cerrarModalDocumento();
			this.dispatchEvent(new CustomEvent('actualizado'));
			this[NavigationMixin.Navigate]({
				type: 'standard__namedPage',
				attributes: { pageName: 'filePreview' },
				state: { selectedRecordId: documentoId },
			});
		} catch (error) {
			this.toast('Error', this.mensajeError(error, 'No se pudo generar el documento.'), 'error');
		} finally {
			this.cargando = false;
		}
	}

	// ===== Utilidades =====

	numero(valor) {
		const resultado = Number(valor);
		return Number.isFinite(resultado) ? resultado : 0;
	}

	formatearMonto(valor) {
		return new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(valor || 0);
	}

	formatearFecha(valor) {
		if (!valor) {
			return null;
		}
		const [anio, mes, dia] = String(valor).split('-');
		return `${dia}/${mes}/${anio}`;
	}

	mensajeError(error, predeterminado) {
		return error?.body?.message || error?.message || predeterminado;
	}

	toast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}
}