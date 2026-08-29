public with sharing class AF_SelectProduct {

    private class SelectProductException extends Exception {}

    public class ProductOption {
        public String accountNumberRaw;
        public String displayLabel;
        public String integrationProductType;
        public String currencyCode;
    }

    public class Input {

        @InvocableVariable(required=true)
        public String productsJson;

        @InvocableVariable(required=true)
        public String userSelection;

    }

    public class Output {

        @InvocableVariable
        public String accountNumber;

        @InvocableVariable
        public String productLabel;

        @InvocableVariable
        public String productLine;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String currencyCode;

    }

    @InvocableMethod(label='Seleccionar producto del cliente')
    public static List<Output> selectProduct(List<Input> inputs){

        List<Output> outputs = new List<Output>();

        for (Input i : inputs) {

            Output o = new Output();
            o.success = false;

            try {

                if (String.isBlank(i.productsJson)) {
                    throw new SelectProductException('No hay productos para seleccionar.');
                }

                if (String.isBlank(i.userSelection)) {
                    throw new SelectProductException('Debe indicar una opción.');
                }

                List<ProductOption> products =
                    (List<ProductOption>)
                    JSON.deserialize(i.productsJson, List<ProductOption>.class);

                if (products == null || products.isEmpty()) {
                    throw new SelectProductException('No hay productos disponibles.');
                }

                Integer index;

                // 🔹 INTENTA COMO NÚMERO
                try {
                    index = Integer.valueOf(i.userSelection.trim()) - 1;
                } catch (Exception e) {

                    // 🔥 SI NO ES NÚMERO → BUSCAR POR TEXTO
                    for (Integer j = 0; j < products.size(); j++) {

                        if (products[j].displayLabel != null &&
                            i.userSelection.toLowerCase().contains(
                                products[j].displayLabel.toLowerCase()
                            )) {
                            index = j;
                            break;
                        }
                    }

                    if (index == null) {
                        throw new SelectProductException(
                            'No pude identificar el producto. Indicá el número (1, 2, 3).'
                        );
                    }
                }

                if (index < 0 || index >= products.size()) {
                    throw new SelectProductException('La opción seleccionada no es válida.');
                }

                ProductOption selectedProduct = products[index];

                if (String.isBlank(selectedProduct.accountNumberRaw)) {
                    throw new SelectProductException('Cuenta inválida.');
                }

                if (String.isBlank(selectedProduct.integrationProductType)) {
                    throw new SelectProductException('Tipo de producto no definido.');
                }

                o.accountNumber = selectedProduct.accountNumberRaw;
                o.productLabel = selectedProduct.displayLabel;
                o.productLine = selectedProduct.integrationProductType;
                o.currencyCode = selectedProduct.currencyCode;
                o.message = 'Seleccionaste: ' + selectedProduct.displayLabel;
                o.success = true;

            } catch (Exception e) {

                o.message = e.getMessage();
                o.success = false;

            }

            outputs.add(o);
        }

        return outputs;
    }
}