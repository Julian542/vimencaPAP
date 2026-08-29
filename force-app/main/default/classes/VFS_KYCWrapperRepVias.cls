public class VFS_KYCWrapperRepVias {
    public String name { get; set; }
    public String noIdentificacion { get; set; }
    public String telefono { get; set; }
    public String correoElectronico { get; set; }

    public VFS_KYCWrapperRepVias(String name, String noIdentificacion, String telefono, String correoElectronico) {
        this.name = name;
        this.noIdentificacion = noIdentificacion;
        this.telefono = telefono;
        this.correoElectronico = correoElectronico;
    }
}