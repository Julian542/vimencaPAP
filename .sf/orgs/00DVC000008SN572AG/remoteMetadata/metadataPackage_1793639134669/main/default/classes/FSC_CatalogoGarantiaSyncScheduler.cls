// Programa la sincronizacion diaria del catalogo de garantias. Un Schedulable no puede hacer callouts,
// por eso solo encola FSC_CatalogoGarantiaSyncJob.
public with sharing class FSC_CatalogoGarantiaSyncScheduler implements Schedulable {
	public static final String NOMBRE_PROGRAMACION = 'FSC Sincronizacion Catalogo Garantias';
	public static final String CRON_DIARIO = '0 0 2 * * ?';

	// Los tests usan otro nombre para no chocar con la programacion real de la org.
	@TestVisible
	private static String nombreProgramacion = NOMBRE_PROGRAMACION;

	public static Id programarDiario() {
		return System.schedule(nombreProgramacion, CRON_DIARIO, new FSC_CatalogoGarantiaSyncScheduler());
	}

	public void execute(SchedulableContext context) {
		System.enqueueJob(new FSC_CatalogoGarantiaSyncJob());
	}
}